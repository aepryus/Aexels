//
//  IntoTheLightRenderer.swift
//  Aexels
//
//  The lab: numerically verify that the cupola algorithm reproduces LW.
//
//   - Disc: closed-form Liénard–Wiechert (the analytic target).
//
//   - Sensor field: a 128×240 polar (R, θ) grid, accumulated in real
//     time on the GPU.  Every tick, every live ping atomic-adds its
//     toggle-aware weight (|𝐂|/R) into the cell it sits in.  The
//     buffer literally is the running simulation's output — no
//     phantoms, no σ kernel, no curvature correction.
//
//   - Pings (drawn as dots over the disc): each body sampled from
//     the sensor field at its centre.  As volleys propagate outward,
//     the field fills band by band; when toggles agree, the ping
//     bodies converge onto the disc band beneath them; when they
//     don't, they visibly diverge.  Toggle / β change clears the
//     sensor and the field rebuilds from c outward.
//

import Acheron
import MetalKit
import simd

enum ItLFieldMode: UInt32 {
    case electric = 0
    case magnetic = 1
    case radiation = 2
}

private struct ItLLWEContext {
    var cameraPos: SIMD2<Float>
    var cameraBounds: SIMD2<Float>
    var beta: SIMD2<Float>
    var fieldMode: UInt32
    var _pad: UInt32 = 0
    // Radiation-mode parameters.  sourceCenter = oscillation midpoint
    // in world coords.  radiationPhase = ω·t accumulated; radiationOmega
    // and radiationAmplitude as named.  c = ping speed (3 here).  The
    // low-β dipole closed form uses all of these:
    //   F_rad ∝ -A ω² sin(θ) cos(phase - ω R/c) / (c² R)
    var sourceCenter: SIMD2<Float> = .zero
    var radiationPhase: Float = 0
    var radiationOmega: Float = 0
    var radiationAmplitude: Float = 0
    var c: Float = 3.0
}

private struct ItLPingDraw {
    var position: SIMD2<Float>
    var cupola: SIMD2<Float>   // C = n̂_em − β_em
    var Cdot: SIMD2<Float>     // Ċ = dC/dt at emission (= −β̇)
    var velocity: SIMD2<Float> // unit n̂_em (engine scales by c at tic-time)
    var isPhantom: UInt32      // 1 = phantom wave ping (forces body-only render)
    var _pad: UInt32 = 0
}

private struct ItLPingFragCtx {
    var cameraPos: SIMD2<Float>
    var colormapExtent: Float
    var beta: Float
    var fullPingsOn: UInt32
    var magnitudeOn: UInt32
    var fieldMode: UInt32
    var oldFieldMode: UInt32
    var radiationCalRef: Float
    var _pad: UInt32 = 0
}

private struct ItLAccumCtx {
    var sourcePos: SIMD2<Float>
    var aetherTranslation: SIMD2<Float>
    var colormapExtent: Float
    var c: Float
    var pingCount: UInt32
    var magnitudeOn: UInt32
    var fieldMode: UInt32
    var _pad: UInt32 = 0
}

// Phantom calc visualization: each commit kicks off a phantom wave that
// runs interleaved with rendering, advancing enough ticks per frame to
// finish in roughly this many frames regardless of velocity.  The
// phantom pings render as an expanding wavefront, and behind them the
// new field fills into pulseSensorBuffer.  Per-pixel, the ping fragment
// shader picks pulseSensorBuffer (new) where the wave has deposited
// data and sensorBuffer (old) where it hasn't yet — so the transition
// from old to new colours is visibly anchored to the wavefront.
private let kPhantomTargetFrames: Int = 30


private let kColormapMR = 128
private let kColormapMTheta = 240
private let kColormapExtent: Float = 700
private let kPulsePings: Int32 = 8500
// Slow-direction wavefront takes extent / ((1−β)·c) ticks; cap so the
// pulse buffer doesn't blow out at extreme β.
private let kMaxPulseTicks: Int = 1000

// Radiation mode runs c at 1/3 the standard 3.0 so the dipole
// wavefront propagates more slowly and the lobe structure is easier
// to read.  Applied consistently across the live universe, the
// atlas phantom, source kinematics, calibration, and the shader's
// analytic disc when fieldMode == .radiation.
private let kRadiationC: Double = 1.0

class IntoTheLightRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let aetherPipelineState: MTLRenderPipelineState
    private let lwePipelineState: MTLRenderPipelineState
    private let loopPipelineState: MTLRenderPipelineState
    private let pingPipelineState: MTLRenderPipelineState
    private let accumPipelineState: MTLComputePipelineState
    private let cameraBuffer: MTLBuffer
    private let lweBuffer: MTLBuffer
    private let pingFragBuffer: MTLBuffer
    private let backgroundTexture: MTLTexture
    // sensorBuffer holds the last completed field (sampled as the
    // fallback "old colours").  pulseSensorBuffer is the in-progress
    // target the active phantom deposits into; when the phantom
    // finishes, its contents are blit-copied into sensorBuffer.  The
    // ping fragment shader reads both: it picks pulseSensorBuffer
    // where the wave has deposited data and sensorBuffer where it
    // hasn't — so the colour transition rides the wavefront.
    private let sensorBuffer: MTLBuffer
    private let pulseSensorBuffer: MTLBuffer
    private let pulsePingsBuffer: MTLBuffer

    weak var view: MTKView?

    // User-intent settings.  velocity is updated live by the slider's
    // onChange — the analytic disc reads it directly, so it tracks the
    // thumb without touching the model.  The cupola/sensor rebuild only
    // happens on commit() (slider release, or magnitude/aberration tap).
    var velocity: Double = 0.70

    // E/B defaults; ControlsTab.applyModePresets re-sets these to 36/5
    // (the radiation icon-view values) when entering R, and restores
    // 120/12 when entering E or B.
    var pingsPerVolley: Int32 = 120
    var timeStepsPerVolley: Int = 12
    var autoOn: Bool = true
    // When on (default for E/B), each ping renders as body + cupola
    // vector arrow + head.  Off renders just the body dot — which is
    // the radiation-lab icon view.  ControlsTab flips this to false
    // when entering R mode and back to true when entering E/B, so
    // each lab opens with its preferred view by default.
    var fullPingsOn: Bool = true
    // When on (default), the analytic Liénard–Wiechert disc is drawn
    // beneath the pings as the reference target.  Off shows just the
    // cupola algorithm's output.
    var analyticDiscOn: Bool = true

    // When on, ping arms render as the *delta* cupola: in the engine's
    // dimensionless convention C = n̂_em − β_src, so the delta is
    // C − n̂_em = −β_src(t_em) — the source's β at emission, with the
    // dominant outward thrust subtracted off.  In E mode at β=0 the
    // delta is zero (no arms).  In E mode with drift it's a constant
    // arrow showing the aether-drift offset, same on every ping.  In
    // R mode it oscillates: consecutive radial shells were emitted at
    // consecutive source-oscillation phases, so delta arms alternate
    // direction across the red/blue boundaries on the analytic disc.
    // Default off.  When on, the rendered arrow = cupola − n̂_em =
    // −β_src.  In E/B with aether drift β is constant, so every arrow
    // points the same direction (the historical "all pings point left"
    // artifact when this defaulted on).  The control is exposed only
    // in the radiation tab; ControlsTab forces this false on every
    // mode switch (including into R), so the user can opt in within
    // R but can never carry it into E/B where it's not meaningful.
    var deltaCupolaOn: Bool = false

    // Radiation-mode only: when on, the camera follows the oscillating
    // teslon so the source stays centred and the aether grid streams
    // past.  When off (default), the camera holds its position in the
    // aether frame and you see the source actually swing across the
    // view — that's the more revealing demo, so we default off.
    var radiationTracksSource: Bool = false

    // Radiation-mode source motion parameters.  Live values — read by
    // draw each frame so slider drags are visible immediately.  When
    // either changes in radiation mode, the atlas is invalidated and
    // rebuilt against the new parameters.
    var radiationOmega: Double = 0.06 {        // rad/tic
        didSet {
            if fieldMode == .radiation && oldValue != radiationOmega {
                radiationAtlasReady = false
                commit()
            }
        }
    }
    var radiationAmplitude: Double = 5.0 {     // world units of swing
        didSet {
            if fieldMode == .radiation && oldValue != radiationAmplitude {
                radiationAtlasReady = false
                commit()
            }
        }
    }

    // Tap-to-toggle settings commit on every change.  In radiation
    // mode both toggles affect the atlas's deposition rules, so the
    // current atlas must be discarded — commit() then triggers a
    // rebuild via startRadiationAtlas.
    var magnitudeOn: Bool = true {
        didSet {
            if fieldMode == .radiation && oldValue != magnitudeOn {
                radiationAtlasReady = false
            }
            commit()
        }
    }

    var aberrationOn: Bool = true {
        didSet {
            if fieldMode == .radiation && oldValue != aberrationOn {
                radiationAtlasReady = false
            }
            commit()
        }
    }

    // Field being verified: electric (rainbow LW-E) or magnetic (signed
    // diverging LW-B).  The analytic disc reads user-intent fieldMode
    // immediately; the cupola sensor field rebuilds via commit so the
    // ping coloring follows after the phantom calc finishes.
    var fieldMode: ItLFieldMode = .electric {
        didSet { commit() }
    }

    // Called by the velocity slider's onRelease (and on init) to commit
    // the current intent state.  Starts (or restarts) a visible phantom
    // wave that rebuilds the sensor field over the next ~30 frames.
    func commit() {
        startPhantom()
    }

    // Engine-applied state.  Updated synchronously inside startPhantom.
    // Initialised to match the user-intent defaults so the first
    // loadUniverse can configure the C engine without a commit.
    private var engineVelocity: Double = 0.70
    private var engineMagnitudeOn: Bool = true
    private var engineAberrationOn: Bool = true
    private var engineFieldMode: ItLFieldMode = .electric
    // Mode of the LAST COMPLETED phantom — i.e., the mode whose
    // deposition rules produced the data currently in sensorBuffer.
    // The ping shader uses this when sampling the old buffer so the
    // colours ahead of the wave match what the user saw before commit.
    private var engineOldFieldMode: ItLFieldMode = .electric

    // Phantom wave state — populated by startPhantom, advanced in draw.
    // Public read so the controls tab can drive a "wave still running"
    // indicator (the slow direction can run well after the visible
    // wavefront has exited the disc).
    private(set) var phantomActive: Bool = false
    private var phantomUniverse: UnsafeMutablePointer<SCUniverse>?
    private var phantomCamera: UnsafeMutablePointer<SCCamera>?
    private var phantomTicksTotal: Int = 0
    private var phantomTicksCompleted: Int = 0
    private var phantomTicksPerFrame: Int = 1
    // Captured intent state for the kernel context — read live during
    // each per-frame deposit so the phantom uses consistent parameters.
    private var phantomVelocity: Double = 0
    private var phantomMagnitudeOn: Bool = true
    private var phantomFieldMode: ItLFieldMode = .electric

    // Radiation atlas: a ring of N sensor-sized snapshot buffers,
    // pre-computed once per (ω, A) combo by a dense phantom that
    // mirrors the live source's oscillation.  Live pings sample
    // snapshots[k] for their body colour, where k indexes the current
    // source phase.  Decouples per-frame compute from sim quality —
    // the phantom can run with many more pings than the live cloud,
    // killing Poisson noise without affecting render speed or the
    // live-cloud density slider.
    private var radiationAtlasSnapshots: [MTLBuffer] = []
    private var radiationAtlasN: Int = 0
    private var radiationAtlasReady: Bool = false
    // Public read-only signal for UI code that needs to know whether
    // the radiation atlas is still building (used by ControlsTab to
    // pump frames synchronously after toggles like magnitude/aberration
    // when the sim is paused).
    var isRadiationAtlasReady: Bool { radiationAtlasReady }
    private var radiationAtlasPhantomUniverse: UnsafeMutablePointer<SCUniverse>?
    private var radiationAtlasPhantomCamera: UnsafeMutablePointer<SCCamera>?
    private var radiationAtlasPhantomPhase: Double = 0
    private var radiationAtlasTicksTotal: Int = 0
    private var radiationAtlasTicksCompleted: Int = 0
    private var radiationAtlasCaptureStart: Int = 0
    private var radiationAtlasOmega: Double = 0
    private var radiationAtlasAmplitude: Double = 0
    // Snapped omega = 2π / N.  The user's radiationOmega rarely divides
    // 2π evenly, so round(2π/ω) gives an N where ω·N ≠ 2π exactly.
    // That tiny drift accumulates across atlas-build cycles and causes
    // one snapshot index near the phase-wrap point to be consistently
    // under-deposited — visible as a single grey-heavy frame once per
    // period in the live render.  Snapping ω to 2π/N (a ~0.3% nudge)
    // makes the phase wrap exactly each N ticks, so every snapshot
    // gets uniform coverage.  Used by both the atlas build AND the live
    // source kinematics so atlas writes and live reads index the same
    // way.
    private var radiationEffectiveOmega: Double = 0
    // Per-frame phantom-tick budget while atlas is building.  1 = the
    // E/B phantom's pace, so the radiation phantom wave is a visible
    // expanding cloud at the same speed (= c).  Build takes a few
    // seconds, but the phantom is the central visible mechanism — it
    // SHOULD be visible while it works, exactly like E/B.
    private var radiationAtlasTicksPerFrame: Int = 1

    private var universe: UnsafeMutablePointer<SCUniverse>?
    private var teslon: UnsafeMutablePointer<SCTeslon>?
    private var camera: UnsafeMutablePointer<SCCamera>?
    private var universeWidth: Double = 0
    private var universeHeight: Double = 0
    private var tickCount: Int = 0
    private var lastTickTime: CFTimeInterval = CACurrentMediaTime()
    // Phase of the radiation-mode oscillation.  Reset to 0 on entry to
    // radiation so the source always starts at the midpoint instead of
    // snapping to some arbitrary position based on accumulated tickCount.
    private var radiationPhase: Double = 0
    // Midpoint of the radiation oscillation, captured from the teslon's
    // position at the moment of entry.  Using the teslon's current spot
    // avoids snapping it (and the in-flight ping cloud) back to universe
    // centre — pings carry over visually intact.
    private var radiationCenterX: Double = 0
    private var radiationCenterY: Double = 0

    init?(view: MTKView) {
        self.view = view
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = commandQueue
        view.device = device

        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<NorthCamera>.size, options: .storageModeShared) else { return nil }
        self.cameraBuffer = cameraBuffer

        guard let lweBuffer = device.makeBuffer(length: MemoryLayout<ItLLWEContext>.size, options: .storageModeShared) else { return nil }
        self.lweBuffer = lweBuffer

        guard let pingFragBuffer = device.makeBuffer(length: MemoryLayout<ItLPingFragCtx>.size, options: .storageModeShared) else { return nil }
        self.pingFragBuffer = pingFragBuffer

        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        guard let sensorBuf = device.makeBuffer(length: sensorByteCount, options: .storageModeShared) else { return nil }
        memset(sensorBuf.contents(), 0, sensorByteCount)
        self.sensorBuffer = sensorBuf

        guard let pulseSensorBuf = device.makeBuffer(length: sensorByteCount, options: .storageModeShared) else { return nil }
        memset(pulseSensorBuf.contents(), 0, sensorByteCount)
        self.pulseSensorBuffer = pulseSensorBuf

        // Pulse-time slab: kMaxPulseTicks × 8500 pings, one offset per
        // tick.  Each tick's slice is written by CPU then consumed by
        // GPU on a single command buffer — distinct offsets avoid the
        // read/write race that one shared slab would have.
        let pulseSize = kMaxPulseTicks * Int(kPulsePings) * MemoryLayout<ItLPingDraw>.stride
        guard let pulseBuf = device.makeBuffer(length: pulseSize, options: .storageModeShared) else { return nil }
        self.pulsePingsBuffer = pulseBuf

        let library = device.makeDefaultLibrary()!

        let aetherDesc = MTLRenderPipelineDescriptor()
        aetherDesc.vertexFunction = library.makeFunction(name: "northAetherVertexShader")
        aetherDesc.fragmentFunction = library.makeFunction(name: "northAetherFragmentShader")
        aetherDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        guard let aetherState = try? device.makeRenderPipelineState(descriptor: aetherDesc) else { return nil }
        self.aetherPipelineState = aetherState

        let lweDesc = MTLRenderPipelineDescriptor()
        lweDesc.vertexFunction = library.makeFunction(name: "itlLWEVertexShader")
        lweDesc.fragmentFunction = library.makeFunction(name: "itlLWEFragmentShader")
        lweDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        lweDesc.colorAttachments[0].isBlendingEnabled = true
        lweDesc.colorAttachments[0].rgbBlendOperation = .add
        lweDesc.colorAttachments[0].alphaBlendOperation = .add
        lweDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        lweDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        lweDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        lweDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let lweState = try? device.makeRenderPipelineState(descriptor: lweDesc) else { return nil }
        self.lwePipelineState = lweState

        let loopDesc = MTLRenderPipelineDescriptor()
        loopDesc.vertexFunction = library.makeFunction(name: "northLoopVertexShader")
        loopDesc.fragmentFunction = library.makeFunction(name: "northLoopFragmentShader")
        loopDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        loopDesc.colorAttachments[0].isBlendingEnabled = true
        loopDesc.colorAttachments[0].rgbBlendOperation = .add
        loopDesc.colorAttachments[0].alphaBlendOperation = .add
        loopDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        loopDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        loopDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        loopDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let loopState = try? device.makeRenderPipelineState(descriptor: loopDesc) else { return nil }
        self.loopPipelineState = loopState

        let pingDesc = MTLRenderPipelineDescriptor()
        pingDesc.vertexFunction = library.makeFunction(name: "itlPingVertexShader")
        pingDesc.fragmentFunction = library.makeFunction(name: "itlPingFragmentShader")
        pingDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pingDesc.colorAttachments[0].isBlendingEnabled = true
        pingDesc.colorAttachments[0].rgbBlendOperation = .add
        pingDesc.colorAttachments[0].alphaBlendOperation = .add
        pingDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pingDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pingDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        pingDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let pingState = try? device.makeRenderPipelineState(descriptor: pingDesc) else { return nil }
        self.pingPipelineState = pingState

        guard let accumFn = library.makeFunction(name: "itlAccumulateKernel"),
              let accumState = try? device.makeComputePipelineState(function: accumFn) else { return nil }
        self.accumPipelineState = accumState

        let image = Engine.renderHex(size: CGSize(width: Screen.height, height: Screen.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let texture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB: false]) else { return nil }
        self.backgroundTexture = texture

        super.init()
        view.delegate = self
    }

    deinit {
        // Release any in-flight phantom universe; only its container is
        // owned here, the sensor buffers are MTLBuffer-managed.
        if let phantomUniverse { SCUniverseRelease(phantomUniverse) }
        if let radiationAtlasPhantomUniverse { SCUniverseRelease(radiationAtlasPhantomUniverse) }
        if let universe { SCUniverseRelease(universe) }
    }

// Universe =======================================================================================
    private func loadUniverse(width: Double, height: Double) {
        // Cancel any in-flight phantom and tear down its universe so we
        // don't end up pointing into freed memory.
        if let phantomUniverse {
            SCUniverseRelease(phantomUniverse)
            self.phantomUniverse = nil
            self.phantomCamera = nil
            self.phantomActive = false
        }
        if let radiationAtlasPhantomUniverse {
            SCUniverseRelease(radiationAtlasPhantomUniverse)
            self.radiationAtlasPhantomUniverse = nil
            self.radiationAtlasPhantomCamera = nil
            self.radiationAtlasReady = false
        }

        if let universe { SCUniverseRelease(universe) }
        let u = SCUniverseCreate(width, height)
        universe = u
        universeWidth = width
        universeHeight = height
        SCUniverseSetC(u, 3.0)
        teslon = SCUniverseCreateTeslon(u, width/2, height/2, 0, 0, 1.0, 1, 0)
        camera = SCUniverseCreateCamera(u, width/2, height/2, 0, 0)
        SCUniverseSetAberration(u, engineAberrationOn ? 1 : 0)
        SCCameraSetWalls(camera, 0)
        SCUniverseSetSpeed(u, engineVelocity)
        tickCount = 0
        let byteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        memset(sensorBuffer.contents(), 0, byteCount)
        memset(pulseSensorBuffer.contents(), 0, byteCount)
        // Kick the initial phantom so the field gets populated.  The
        // controls panel's indicator now shows when it's running, so
        // the user can see (and wait for) it instead of accidentally
        // cancelling it with an early commit.
        DispatchQueue.main.async { [weak self] in self?.startPhantom() }
    }

// Phantom wave =================================================================================
    // Called synchronously on the main thread.  Cancels any in-flight
    // phantom, applies the new intent state to the live universe
    // immediately (so auto-fire emission matches the new mode), and
    // starts a fresh phantom calc whose pings will visibly expand from
    // the source over the next ~30 frames.
    private func startPhantom() {
        let w = universeWidth
        let h = universeHeight
        guard w > 0, h > 0 else { return }

        // Capture intent state.
        let intentVelocity = self.velocity
        let intentMagnitudeOn = self.magnitudeOn
        let intentAberrationOn = self.aberrationOn
        let intentFieldMode = self.fieldMode

        // Mode-transition resets for radiation entry/exit — same logic
        // as the previous apply.  Run BEFORE SCUniverseSetSpeed so the
        // teslon's v is whatever post-frame value we want (zero would
        // strand it; intentVelocity makes SetSpeed's transform an
        // identity when the slider hasn't moved).
        if engineFieldMode == .radiation && intentFieldMode != .radiation {
            if let teslon = self.teslon, let camera = self.camera {
                teslon.pointee.pos.x = w / 2
                teslon.pointee.pos.y = h / 2
                teslon.pointee.v.x = intentVelocity
                teslon.pointee.v.y = 0
                teslon.pointee.a.x = 0
                teslon.pointee.a.y = 0
                camera.pointee.pos.x = w / 2
                camera.pointee.pos.y = h / 2
                camera.pointee.v.x = intentVelocity
                camera.pointee.v.y = 0
            }
        }
        if engineFieldMode != .radiation && intentFieldMode == .radiation {
            radiationPhase = 0
            if let teslon = self.teslon {
                radiationCenterX = teslon.pointee.pos.x
                radiationCenterY = teslon.pointee.pos.y
            }
        }

        // Apply settings to live universe immediately so auto-fire
        // pings from this frame forward emit with the new mode/velocity.
        if let live = self.universe {
            SCUniverseSetC(live, intentFieldMode == .radiation ? kRadiationC : 3.0)
            SCUniverseSetSpeed(live, intentVelocity)
            SCUniverseSetAberration(live, intentAberrationOn ? 1 : 0)
        }
        engineVelocity = intentVelocity
        engineMagnitudeOn = intentMagnitudeOn
        engineAberrationOn = intentAberrationOn
        engineFieldMode = intentFieldMode

        // Cancel any in-flight phantom — its partial pulseSensorBuffer
        // data is discarded.  sensorBuffer still holds the last
        // completed field, so pings keep their old colours until the
        // new phantom wave sweeps through.
        if let prev = phantomUniverse {
            SCUniverseRelease(prev)
            phantomUniverse = nil
            phantomCamera = nil
        }
        // Also cancel any in-flight radiation atlas build.  Snapshot
        // buffers are kept (so a re-entry into radiation with matching
        // params can re-use them) but the in-flight phantom dies.
        if let prev = radiationAtlasPhantomUniverse {
            SCUniverseRelease(prev)
            radiationAtlasPhantomUniverse = nil
            radiationAtlasPhantomCamera = nil
            // Leaving the build incomplete: mark not-ready so the next
            // re-entry rebuilds rather than reads partial data.
            if intentFieldMode != .radiation {
                radiationAtlasReady = false
            }
        }

        // Reset pulseSensorBuffer to zero — empty cells will fall back
        // to sensorBuffer in the shader, so the world stays coloured
        // by the old field ahead of the wave.
        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        memset(pulseSensorBuffer.contents(), 0, sensorByteCount)

        // Radiation mode: kick off the atlas build (a dense phantom that
        // captures one period of the field as N snapshots indexed by
        // source phase).  Live pings render normally; their body colours
        // sample snapshots[currentPhaseIndex] every frame.  See
        // startRadiationAtlas / advanceRadiationAtlas.
        if intentFieldMode == .radiation {
            startRadiationAtlas()
            return
        }

        // Build the phantom universe.  Place the teslon at the live
        // teslon's current position so the wave emanates from where
        // the source actually is (matters in radiation mode where the
        // source oscillates away from world centre).
        let pu = SCUniverseCreate(w, h)!
        SCUniverseSetC(pu, 3.0)
        let centreX = teslon?.pointee.pos.x ?? (w / 2)
        let centreY = teslon?.pointee.pos.y ?? (h / 2)
        _ = SCUniverseCreateTeslon(pu, centreX, centreY, 0, 0, 1.0, 1, 0)
        let pc = SCUniverseCreateCamera(pu, centreX, centreY, 0, 0)!
        SCCameraSetWalls(pc, 0)
        SCUniverseSetAberration(pu, intentAberrationOn ? 1 : 0)
        SCUniverseSetSpeed(pu, intentVelocity)
        SCUniversePing(pu, kPulsePings)

        let slowSpeed = max(0.05, (1.0 - intentVelocity) * 3.0)
        phantomTicksTotal = min(kMaxPulseTicks,
                                Int(ceil(Double(kColormapExtent) / slowSpeed)) + 4)
        phantomTicksCompleted = 0
        // One tick per draw frame.  The phantom wave moves at c (same
        // rate as live auto-fire pings) so its expansion looks physical.
        // Animation duration varies with β: low β finishes in ~4 sec,
        // high β can take 10+ sec along the slow direction — that's
        // the actual speed of light in this medium, and watching it
        // play out is the point.
        phantomTicksPerFrame = 1
        phantomVelocity = intentVelocity
        phantomMagnitudeOn = intentMagnitudeOn
        phantomFieldMode = intentFieldMode
        phantomUniverse = pu
        phantomCamera = pc
        phantomActive = true
    }

    // Advance the in-flight phantom by up to N ticks, encoding the
    // deposits into the supplied command buffer.  Called from draw()
    // once per frame.  Returns when the phantom finishes or N ticks
    // have been consumed.
    private func advancePhantom(into cmdBuf: MTLCommandBuffer, ticks: Int) {
        guard phantomActive, let pu = phantomUniverse, let pc = phantomCamera else { return }
        let strideSize = MemoryLayout<ItLPingDraw>.stride
        let tgWidth = min(accumPipelineState.maxTotalThreadsPerThreadgroup, 64)

        let toDo = min(ticks, phantomTicksTotal - phantomTicksCompleted)
        for _ in 0..<toDo {
            SCUniverseTic(pu)
            let pingCount = Int(pu.pointee.pingCount)
            phantomTicksCompleted += 1
            if pingCount <= 0 { continue }

            // The pulse-pings slab has kMaxPulseTicks slots; recycle
            // by tick index modulo that.
            let slotIndex = phantomTicksCompleted % kMaxPulseTicks
            let offset = slotIndex * Int(kPulsePings) * strideSize
            let slot = pulsePingsBuffer.contents()
                .advanced(by: offset)
                .bindMemory(to: ItLPingDraw.self, capacity: pingCount)
            for i in 0..<pingCount {
                let p = pu.pointee.pings[i]!
                slot[i] = ItLPingDraw(
                    position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                    cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                    Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                    velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                    isPhantom: 0   // deposit-kernel input; flag not consulted there
                )
            }

            var ctx = ItLAccumCtx(
                sourcePos: SIMD2<Float>(Float(pc.pointee.pos.x), Float(pc.pointee.pos.y)),
                aetherTranslation: SIMD2<Float>(-Float(phantomVelocity) * 3.0, 0),
                colormapExtent: kColormapExtent,
                c: 3.0,
                pingCount: UInt32(pingCount),
                magnitudeOn: phantomMagnitudeOn ? 1 : 0,
                fieldMode: phantomFieldMode.rawValue
            )
            let enc = cmdBuf.makeComputeCommandEncoder()!
            enc.setComputePipelineState(accumPipelineState)
            enc.setBytes(&ctx, length: MemoryLayout<ItLAccumCtx>.size, index: 0)
            enc.setBuffer(pulsePingsBuffer, offset: offset, index: 1)
            enc.setBuffer(pulseSensorBuffer, offset: 0, index: 2)
            let tgs = MTLSize(width: (pingCount + tgWidth - 1) / tgWidth, height: 1, depth: 1)
            enc.dispatchThreadgroups(tgs,
                                     threadsPerThreadgroup: MTLSize(width: tgWidth, height: 1, depth: 1))
            enc.endEncoding()
        }

        if phantomTicksCompleted >= phantomTicksTotal {
            // Phantom finished.  Blit the freshly-built pulse field
            // into sensorBuffer (so subsequent frames sample the new
            // field directly) and release the phantom universe.  Stamp
            // engineOldFieldMode to the mode that produced this data —
            // future commits will use it to render the fallback colours
            // ahead of their new wave correctly.
            let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
            if let blit = cmdBuf.makeBlitCommandEncoder() {
                blit.copy(from: pulseSensorBuffer, sourceOffset: 0,
                          to: sensorBuffer, destinationOffset: 0,
                          size: sensorByteCount)
                blit.endEncoding()
            }
            engineOldFieldMode = phantomFieldMode
            SCUniverseRelease(pu)
            phantomUniverse = nil
            phantomCamera = nil
            phantomActive = false
        }
    }

    // Radiation deposit: zero sensorBuffer, run the accumulator once on
    // the LIVE ping cloud with fieldMode=2, targeting sensorBuffer
    // directly.  Each frame produces a fresh snapshot — no phantom, no
    // dual buffer.  Constructively-summed deposits at each cell give
    // the instantaneous radiation field at that point (see comment at
    // call site in draw()).
    private func depositLiveCloudForRadiation(into cmdBuf: MTLCommandBuffer) {
        guard let universe else { return }
        let pingCount = Int(universe.pointee.pingCount)
        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size

        // CPU zeroing — sensorBuffer is .storageModeShared, and Metal
        // serialises CPU writes before subsequent GPU commands as long
        // as the writes happen before the encoder runs.
        memset(sensorBuffer.contents(), 0, sensorByteCount)
        // Also reset pulseSensorBuffer so the dual-buffer logic in the
        // ping fragment shader (used by E/B) reads clean zeros if the
        // user flips back to E/B from R — avoids stale R deposits
        // bleeding into the next mode's render.
        memset(pulseSensorBuffer.contents(), 0, sensorByteCount)

        if pingCount <= 0 { return }

        // Build a temporary ping buffer for the deposit.  Live universe's
        // pings are read every frame; this buffer is throwaway.
        var pings: [ItLPingDraw] = []
        pings.reserveCapacity(pingCount)
        for i in 0..<pingCount {
            let p = universe.pointee.pings[i]!
            pings.append(ItLPingDraw(
                position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                isPhantom: 0
            ))
        }
        guard let pingsBuf = device.makeBuffer(bytes: pings,
                                               length: pings.count * MemoryLayout<ItLPingDraw>.stride,
                                               options: .storageModeShared) else { return }

        // Source-position reference for the polar grid.
        //
        // The analytic disc anchors to `radiationCenter` — the fixed
        // oscillation midpoint — so its (R, θ) grid is steady regardless
        // of where the teslon is right now.  The cupola accumulator must
        // use the SAME reference, otherwise the cupola's polar grid
        // swings with the source and the simulation's lobes appear
        // shifted relative to the analytic (we hit this bug: source at
        // its left extreme → cupola lobes apparently favouring the left).
        //
        // For low-β radiation the midpoint is the correct reference: the
        // far-field formula uses the source's "central" position and
        // treats the oscillation as a small perturbation.  Using current
        // teslon.pos would amount to a different (less accurate) frame
        // choice that breaks comparison with the closed form.
        let sourcePos = SIMD2<Float>(Float(radiationCenterX), Float(radiationCenterY))
        var ctx = ItLAccumCtx(
            sourcePos: sourcePos,
            aetherTranslation: SIMD2<Float>(-Float(engineVelocity * kRadiationC), 0),
            colormapExtent: kColormapExtent,
            c: Float(kRadiationC),
            pingCount: UInt32(pingCount),
            magnitudeOn: engineMagnitudeOn ? 1 : 0,
            fieldMode: ItLFieldMode.radiation.rawValue
        )
        let tgWidth = min(accumPipelineState.maxTotalThreadsPerThreadgroup, 64)
        let enc = cmdBuf.makeComputeCommandEncoder()!
        enc.setComputePipelineState(accumPipelineState)
        enc.setBytes(&ctx, length: MemoryLayout<ItLAccumCtx>.size, index: 0)
        enc.setBuffer(pingsBuf, offset: 0, index: 1)
        enc.setBuffer(sensorBuffer, offset: 0, index: 2)
        let tgs = MTLSize(width: (pingCount + tgWidth - 1) / tgWidth, height: 1, depth: 1)
        enc.dispatchThreadgroups(tgs,
                                 threadsPerThreadgroup: MTLSize(width: tgWidth, height: 1, depth: 1))
        enc.endEncoding()
    }

// Radiation atlas ===============================================================================
    // The radiation field at any cell (R, θ) at any moment depends on
    // the source's state at the retarded emission time.  Since the
    // source motion is strictly periodic, the field at (R, θ, t) is
    // identical to the field at (R, θ, t + T) where T = 2π/ω.  We
    // exploit this by pre-computing a ring of N = round(T) snapshot
    // sensors covering one full source period at high ping density.
    // Live pings then sample snapshots[currentPhaseIndex] for their
    // body colour — runtime cost is just an index calc per frame and
    // a buffer rebinding.

    // Allocate (or reallocate) snapshot buffers for current N.
    private func ensureRadiationAtlasCapacity(_ N: Int) {
        if radiationAtlasN == N && !radiationAtlasSnapshots.isEmpty { return }
        radiationAtlasSnapshots.removeAll(keepingCapacity: true)
        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        for _ in 0..<N {
            if let buf = device.makeBuffer(length: sensorByteCount, options: .storageModeShared) {
                radiationAtlasSnapshots.append(buf)
            }
        }
        radiationAtlasN = N
    }

    // Kick off a fresh atlas build: clear old data, allocate snapshots
    // sized to current ω, create the phantom universe.  Heavy work
    // happens incrementally in advanceRadiationAtlas().
    private func startRadiationAtlas() {
        let rawOmega = max(self.radiationOmega, 1e-6)
        let cSpeed: Double = kRadiationC
        let maxBeta: Double = 0.9

        // N snapshots covering one period.  Clamp to a sane range so we
        // don't blow up memory for very low ω.  Snap omega to 2π/N so
        // the phase wraps exactly each N ticks (see radiationEffectiveOmega).
        let N = max(16, min(512, Int(round(2.0 * .pi / rawOmega))))
        let omega = 2.0 * .pi / Double(N)
        let amplitude = min(self.radiationAmplitude, maxBeta * cSpeed / omega)

        // Skip rebuild if the existing atlas already matches the current
        // params — re-entry into radiation mode is then instant.
        if radiationAtlasReady
            && radiationAtlasOmega == omega
            && radiationAtlasAmplitude == amplitude
            && !radiationAtlasSnapshots.isEmpty {
            radiationEffectiveOmega = omega
            return
        }

        ensureRadiationAtlasCapacity(N)

        // Zero all snapshot buffers so any reads during the build show
        // the empty-cell colour, not stale data from a previous atlas.
        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        for buf in radiationAtlasSnapshots {
            memset(buf.contents(), 0, sensorByteCount)
        }

        // Release any in-flight phantom from a prior aborted build.
        if let prev = radiationAtlasPhantomUniverse {
            SCUniverseRelease(prev)
            radiationAtlasPhantomUniverse = nil
            radiationAtlasPhantomCamera = nil
        }

        // Phantom universe with a teslon at radiationCenter.  We'll
        // override its pos/v/a each tick to drive the oscillation.
        let w = universeWidth
        let h = universeHeight
        guard w > 0, h > 0 else { return }
        let pu = SCUniverseCreate(w, h)!
        SCUniverseSetC(pu, kRadiationC)
        _ = SCUniverseCreateTeslon(pu, radiationCenterX, radiationCenterY, 0, 0, 1.0, 1, 0)
        let pc = SCUniverseCreateCamera(pu, radiationCenterX, radiationCenterY, 0, 0)!
        SCCameraSetWalls(pc, 0)
        // Rule 3 emission anisotropy ON — match the live universe, so
        // the atlas measures the actual cupola algorithm with all its
        // pieces, not a stripped-down approximation.  Any mismatch
        // between this and the analytic disc is a bug to find, not a
        // knob to turn off.
        SCUniverseSetAberration(pu, self.aberrationOn ? 1 : 0)
        SCUniverseSetSpeed(pu, 0)

        radiationAtlasPhantomUniverse = pu
        radiationAtlasPhantomCamera = pc
        radiationAtlasPhantomPhase = 0
        radiationAtlasOmega = omega
        radiationAtlasAmplitude = amplitude
        radiationEffectiveOmega = omega
        // One-period-wide pulse build (E/B-style sweep):
        //   • First N ticks: source oscillates through ONE full period
        //     and emits.  This creates a wave packet exactly one
        //     wavelength (= c·T) wide.
        //   • After that, no more emission — just tic the universe so
        //     the packet propagates outward without grow-from-source
        //     baggage.  Visually identical to the E/B labs' expanding
        //     wavefront, only this one carries a full cycle of source
        //     state instead of a single impulse.
        //   • Total ticks = N + timeToEdge: long enough for the
        //     trailing edge to leave R = colormapExtent.
        //   • Capture happens EVERY tick into snapshot[phase mod N]
        //     using atomic-add into the snapshot buffer directly.
        //     Cell (R, θ) at radius R is touched only when the pulse
        //     is at radius R (a one-tick-wide window per cycle of the
        //     atlas index).  Over the build, each snapshot ends up
        //     with a deposit at every R the pulse passed through,
        //     each at the correct retarded phase = (live phase − ωR/c).
        //     No scratch buffer, no blit — the snapshot IS the
        //     accumulator.
        let timeToEdge = Int(ceil(Double(kColormapExtent) / cSpeed)) + 4
        radiationAtlasCaptureStart = N    // re-purpose: emission ends at this tick
        radiationAtlasTicksTotal = N + timeToEdge
        radiationAtlasTicksCompleted = 0
        radiationAtlasReady = false
        phantomActive = true
    }

    // Advance the atlas phantom by radiationAtlasTicksPerFrame ticks.
    // Each tick: drive teslon's oscillation, emit a dense volley, run
    // the radiation deposit kernel against the cloud (writing into
    // pulseSensorBuffer as a scratch buffer), and during the capture
    // window blit the result into snapshots[(tick − captureStart) % N].
    private func advanceRadiationAtlas(into cmdBuf: MTLCommandBuffer) {
        guard let pu = radiationAtlasPhantomUniverse else { return }
        let cSpeed: Double = kRadiationC
        let omega = radiationAtlasOmega
        let amplitude = radiationAtlasAmplitude
        // Pings per atlas tick.  Higher = denser field but heavier
        // compute and bigger memory footprint over the build's
        // ~radiationAtlasTicksTotal lifetime.
        let pingsPerAtlasTick: Int32 = 480
        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        let tgWidth = min(accumPipelineState.maxTotalThreadsPerThreadgroup, 64)

        let remaining = radiationAtlasTicksTotal - radiationAtlasTicksCompleted
        let toDo = min(radiationAtlasTicksPerFrame, remaining)
        guard toDo > 0 else { return }

        for _ in 0..<toDo {
            let tick = radiationAtlasTicksCompleted
            let emissionTicks = radiationAtlasCaptureStart   // re-purposed: N

            // Drive the source's oscillation only during emission phase.
            // After that the teslon's state doesn't matter — no more
            // pings will be emitted — but we still advance the phase
            // counter so the snapshot index keeps cycling.
            if tick < emissionTicks, pu.pointee.teslonCount > 0,
               let teslon = pu.pointee.teslons[0] {
                let phase = radiationAtlasPhantomPhase
                teslon.pointee.pos.x = radiationCenterX + amplitude * sin(phase)
                teslon.pointee.pos.y = radiationCenterY
                teslon.pointee.v.x = amplitude * omega * cos(phase) / cSpeed
                teslon.pointee.v.y = 0
                teslon.pointee.a.x = -amplitude * omega * omega * sin(phase) / cSpeed
                teslon.pointee.a.y = 0
                SCUniversePing(pu, pingsPerAtlasTick)
            }
            SCUniverseTic(pu)
            radiationAtlasPhantomPhase += omega

            let pingCount = Int(pu.pointee.pingCount)

            if pingCount > 0 {
                // Deposit kernel writes DIRECTLY into the snapshot
                // buffer at the current phase index.  Atomic adds in
                // the kernel mean this accumulates across multiple
                // visits to the same snapshot — each visit deposits
                // at a different annulus (the pulse's current
                // location), so by end-of-build the snapshot is
                // populated at every radius the pulse passed through.
                let twoPi = 2.0 * Double.pi
                var phaseMod = radiationAtlasPhantomPhase.truncatingRemainder(dividingBy: twoPi)
                if phaseMod < 0 { phaseMod += twoPi }
                let step = twoPi / Double(max(radiationAtlasN, 1))
                let snapIdx = Int(round(phaseMod / step)) % max(radiationAtlasN, 1)

                if snapIdx >= 0 && snapIdx < radiationAtlasSnapshots.count {
                    var pings: [ItLPingDraw] = []
                    pings.reserveCapacity(pingCount)
                    for i in 0..<pingCount {
                        let p = pu.pointee.pings[i]!
                        pings.append(ItLPingDraw(
                            position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                            cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                            Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                            velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                            isPhantom: 0
                        ))
                    }
                    if let pingsBuf = device.makeBuffer(bytes: pings,
                                                        length: pings.count * MemoryLayout<ItLPingDraw>.stride,
                                                        options: .storageModeShared) {
                        var ctx = ItLAccumCtx(
                            sourcePos: SIMD2<Float>(Float(radiationCenterX), Float(radiationCenterY)),
                            aetherTranslation: SIMD2<Float>(0, 0),
                            colormapExtent: kColormapExtent,
                            c: Float(kRadiationC),
                            pingCount: UInt32(pingCount),
                            magnitudeOn: 1,
                            fieldMode: ItLFieldMode.radiation.rawValue
                        )
                        let enc = cmdBuf.makeComputeCommandEncoder()!
                        enc.setComputePipelineState(accumPipelineState)
                        enc.setBytes(&ctx, length: MemoryLayout<ItLAccumCtx>.size, index: 0)
                        enc.setBuffer(pingsBuf, offset: 0, index: 1)
                        enc.setBuffer(radiationAtlasSnapshots[snapIdx], offset: 0, index: 2)
                        let tgs = MTLSize(width: (pingCount + tgWidth - 1) / tgWidth, height: 1, depth: 1)
                        enc.dispatchThreadgroups(tgs,
                                                 threadsPerThreadgroup: MTLSize(width: tgWidth, height: 1, depth: 1))
                        enc.endEncoding()
                    }
                }
            }

            radiationAtlasTicksCompleted += 1
            _ = sensorByteCount  // keep symbol live for any future blit use
        }

        // Build finished?  Release phantom, drop indicator, flip the
        // atlas-ready flag so the ping render path starts using it.
        if radiationAtlasTicksCompleted >= radiationAtlasTicksTotal {
            if let pu = radiationAtlasPhantomUniverse {
                SCUniverseRelease(pu)
                radiationAtlasPhantomUniverse = nil
                radiationAtlasPhantomCamera = nil
            }
            radiationAtlasReady = true
            phantomActive = false
        }
    }

    // Pick the snapshot index whose source phase is closest to the
    // live source's current phase.  Phase = radiationPhase mod 2π,
    // mapped into [0, N).
    private func currentRadiationSnapshotIndex() -> Int {
        guard radiationAtlasN > 0 else { return 0 }
        let twoPi = 2.0 * Double.pi
        var phaseMod = radiationPhase.truncatingRemainder(dividingBy: twoPi)
        if phaseMod < 0 { phaseMod += twoPi }
        let step = twoPi / Double(radiationAtlasN)
        var idx = Int(round(phaseMod / step)) % radiationAtlasN
        if idx < 0 { idx += radiationAtlasN }
        return idx
    }

    // Visible atlas phantom — feeds phantom pings into the render as
    // white bodies.  Source emits only during the first N ticks (one
    // full period), so the live ping cloud naturally IS a one-
    // wavelength-wide pulse expanding outward.  No filter needed —
    // every ping in the phantom universe is part of the visible
    // expanding wavefront, exactly as in the E/B labs.
    private func currentRadiationAtlasPingDraws() -> [ItLPingDraw] {
        guard let pu = radiationAtlasPhantomUniverse else { return [] }
        let count = Int(pu.pointee.pingCount)
        if count == 0 { return [] }
        var out: [ItLPingDraw] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            let p = pu.pointee.pings[i]!
            out.append(ItLPingDraw(
                position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                isPhantom: 1   // forces body-only white render
            ))
        }
        return out
    }

// Phantom pings =================================================================================
    // Read the live phantom pings into ItLPingDraw structs for rendering.
    // Empty when no phantom is active.
    private func currentPhantomPingDraws() -> [ItLPingDraw] {
        guard phantomActive, let pu = phantomUniverse else { return [] }
        let count = Int(pu.pointee.pingCount)
        var out: [ItLPingDraw] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            let p = pu.pointee.pings[i]!
            // Delta cupola: engine stores cupola in dimensionless form
            // C/c = n̂_em − β_src (see Sargasso.c: ping->cupola = iQ − tV
            // where tV is the teslon's β).  Subtracting ping.v (= n̂_em)
            // leaves −β_src(t_em) — the source's velocity at emission,
            // dimensionless, with the radial-propagation term stripped.
            let cx: Double = deltaCupolaOn
                ? (p.pointee.cupola.x - p.pointee.v.x)
                : p.pointee.cupola.x
            let cy: Double = deltaCupolaOn
                ? (p.pointee.cupola.y - p.pointee.v.y)
                : p.pointee.cupola.y
            out.append(ItLPingDraw(
                position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                cupola: SIMD2<Float>(Float(cx), Float(cy)),
                Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                isPhantom: 1   // forces body-only render regardless of fullPingsOn
            ))
        }
        return out
    }

// Events =========================================================================================
    func onPing() {
        guard let universe else { return }
        SCUniversePing(universe, pingsPerVolley)
    }

    func onReset() {
        guard let view else { return }
        let w = Double(view.drawableSize.width / view.contentScaleFactor)
        let h = Double(view.drawableSize.height / view.contentScaleFactor)
        loadUniverse(width: w, height: h)
        lastTickTime = CACurrentMediaTime()
    }

    func resyncClock() { lastTickTime = CACurrentMediaTime() }

// MTKViewDelegate ================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let w = Double(size.width / view.contentScaleFactor)
        let h = Double(size.height / view.contentScaleFactor)
        loadUniverse(width: w, height: h)
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }

        let now = CACurrentMediaTime()
        lastTickTime = now

        guard let universe, let camera else { return }

        tickCount += 1

        // Radiation lab: prescribe the source teslon's velocity and
        // acceleration so emitted pings carry rotation + spring rates,
        // and consecutive pings (emitted as the source's β cycles)
        // also have a varying base cupola direction.  Position
        // integrates from v via the engine's pos += v*c each tic.
        // Hardcoded linear oscillation along x for now (controls later).
        // E and B modes leave a = 0, preserving the existing behavior.
        if let teslon, engineFieldMode == .radiation {
            let c: Double = kRadiationC
            // Use the snapped omega (2π/N) so the live source's phase
            // advances at exactly the rate the atlas was built for.
            // Falls back to raw radiationOmega if the atlas hasn't built
            // yet (shouldn't happen — transition into radiation calls
            // startRadiationAtlas before the next draw()).
            let omega: Double = radiationEffectiveOmega > 0 ? radiationEffectiveOmega : radiationOmega
            // Cap peak velocity (A·ω) so the source's β never exceeds
            // a safe sub-c value.  Whichever slider is being pushed,
            // amplitude gets pulled in if the product would otherwise
            // outrun light.
            let maxBeta: Double = 0.9
            let amplitude: Double = min(radiationAmplitude, maxBeta * c / omega)
            let phase = radiationPhase
            radiationPhase += omega
            // Prescribe position directly so the midpoint of oscillation
            // stays anchored to the entry-point centre — without this,
            // Euler integration of v(t) over many cycles drifts.  The
            // centre was captured on transition-into-radiation, which is
            // wherever the teslon was at that moment (NOT universe
            // centre), so the in-flight ping cloud doesn't visually
            // jump.
            teslon.pointee.pos.x = radiationCenterX + amplitude * sin(phase)
            teslon.pointee.pos.y = radiationCenterY
            teslon.pointee.v.x = amplitude * omega * cos(phase) / c
            teslon.pointee.v.y = 0
            teslon.pointee.a.x = -amplitude * omega * omega * sin(phase) / c
            teslon.pointee.a.y = 0
            // Source-tracking camera (default): camera follows teslon
            // so the oscillating source stays visually centred and the
            // aether grid streams past.  Aether-frame camera: pinned to
            // the oscillation midpoint (where the teslon was on entry
            // to radiation) so the source swings symmetrically around
            // screen centre and the existing pings stay where they were.
            if radiationTracksSource {
                camera.pointee.pos = teslon.pointee.pos
                camera.pointee.v = teslon.pointee.v
            } else {
                camera.pointee.pos.x = radiationCenterX
                camera.pointee.pos.y = radiationCenterY
                camera.pointee.v.x = 0
                camera.pointee.v.y = 0
            }
        } else if let teslon {
            teslon.pointee.a.x = 0
            teslon.pointee.a.y = 0
        }

        if autoOn && tickCount % timeStepsPerVolley == 0 {
            // SCUniversePing emits per the universe's aberration flag —
            // Rule-3 when on, uniform when off — so the visible cloud
            // tracks the aberration toggle directly.
            SCUniversePing(universe, pingsPerVolley)
        }
        SCUniverseTic(universe)

        let width = Float(view.drawableSize.width / view.contentScaleFactor)
        let height = Float(view.drawableSize.height / view.contentScaleFactor)

        let cameraPos = SIMD2<Float>(Float(camera.pointee.pos.x), Float(camera.pointee.pos.y))

        var northCamera = NorthCamera(
            position: cameraPos,
            bounds: SIMD2<Float>(width, height),
            hexBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height)),
            velocity: SIMD2<Float>(Float(camera.pointee.v.x), Float(camera.pointee.v.y)),
            hexWidth: Float(10.0 * Screen.s * 3),
            pingVectorsOn: true,
            pongVectorsOn: false,
            photonVectorsOn: false
        )
        memcpy(cameraBuffer.contents(), &northCamera, MemoryLayout<NorthCamera>.size)

        let pingCount = Int(universe.pointee.pingCount)
        var pingDraws: [ItLPingDraw] = []
        pingDraws.reserveCapacity(pingCount)
        for i in 0..<pingCount {
            let p = universe.pointee.pings[i]!
            // See deltaCupolaOn comment on the property.  Engine cupola
            // is dimensionless (n̂_em − β); delta = cupola − n̂_em = −β.
            let cx: Double = deltaCupolaOn
                ? (p.pointee.cupola.x - p.pointee.v.x)
                : p.pointee.cupola.x
            let cy: Double = deltaCupolaOn
                ? (p.pointee.cupola.y - p.pointee.v.y)
                : p.pointee.cupola.y
            pingDraws.append(ItLPingDraw(
                position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                cupola: SIMD2<Float>(Float(cx), Float(cy)),
                Cdot: SIMD2<Float>(Float(p.pointee.Cdot.x), Float(p.pointee.Cdot.y)),
                velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y)),
                isPhantom: 0
            ))
        }
        // Append phantom pings as a visible expanding layer.  They use
        // the same shader as live pings so the wavefront looks like a
        // dense cloud of the same dots, riding outward from the source.
        // For radiation, the atlas phantom is what's expanding — emits
        // continuously as the source oscillates, building up the field.
        pingDraws.append(contentsOf: currentPhantomPingDraws())
        pingDraws.append(contentsOf: currentRadiationAtlasPingDraws())

        var teslons: [NorthLoop] = []
        for i in 0..<Int(universe.pointee.teslonCount) {
            let t = universe.pointee.teslons[i]!
            teslons.append(NorthLoop(
                type: 0,
                position: SIMD2<Float>(Float(t.pointee.pos.x), Float(t.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(t.pointee.v.x), Float(t.pointee.v.y)),
                cupola: SIMD2<Float>(0, 0),
                hyle: Float(t.pointee.hyle)
            ))
        }

        // Analytic disc reads user-intent `velocity` and `fieldMode` so
        // it tracks both the slider and the E/B switch live, even when
        // the worker hasn't yet rebuilt the cupola field.  Radiation
        // mode also passes the source-oscillation parameters so the
        // shader can paint the low-β dipole closed form.
        var lweCtx = ItLLWEContext(
            cameraPos: cameraPos,
            cameraBounds: SIMD2<Float>(width, height),
            beta: SIMD2<Float>(Float(velocity), 0),
            fieldMode: fieldMode.rawValue,
            sourceCenter: SIMD2<Float>(Float(radiationCenterX), Float(radiationCenterY)),
            radiationPhase: Float(radiationPhase),
            radiationOmega: Float(radiationOmega),
            radiationAmplitude: Float(radiationAmplitude),
            c: fieldMode == .radiation ? Float(kRadiationC) : 3.0
        )
        memcpy(lweBuffer.contents(), &lweCtx, MemoryLayout<ItLLWEContext>.size)

        // Cupola pings shade against the engine-applied state so what's
        // drawn matches the sensor field they sample from.  For
        // radiation, calRef = the analytic LW peak amplitude at the
        // perpendicular reference point (0, y_cal):
        //   |F_rad|_peak  =  A·ω² / (c²·y_cal)
        // This is the SAME calRef the analytic disc uses, mirroring
        // how E and B labs calibrate.  No fudge constant — the
        // cupola's bandCoord = 6 at y_cal IF AND ONLY IF the algorithm
        // is producing the correct LW magnitude there.  Any visible
        // band mismatch between the cupola sensor field and the
        // analytic disc is then a real algorithm/implementation bug,
        // not a calibration knob.
        let cSpeed: Double = kRadiationC
        let yCal: Double = Double(kColormapExtent / 7.0)
            / pow(max(1.0 - engineVelocity * engineVelocity, 1e-4), 0.25)
        let radCalRef: Double = (engineFieldMode == .radiation)
            ? radiationAmplitude * radiationOmega * radiationOmega
                / (cSpeed * cSpeed * yCal)
            : 0
        var pingFragCtx = ItLPingFragCtx(
            cameraPos: cameraPos,
            colormapExtent: kColormapExtent,
            beta: Float(engineVelocity),
            fullPingsOn: fullPingsOn ? 1 : 0,
            magnitudeOn: engineMagnitudeOn ? 1 : 0,
            fieldMode: engineFieldMode.rawValue,
            oldFieldMode: engineOldFieldMode.rawValue,
            radiationCalRef: Float(radCalRef)
        )
        memcpy(pingFragBuffer.contents(), &pingFragCtx, MemoryLayout<ItLPingFragCtx>.size)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Sensor deposit pass.
        //
        // E/B modes: phantom-based.  A phantom universe runs its course
        // depositing into pulseSensorBuffer; when it finishes its results
        // get blit-copied into sensorBuffer.
        //
        // R mode: atlas-based.  A dense, one-time phantom build computes
        // a ring of N field snapshots, one per source phase.  Live pings
        // sample snapshots[currentPhase] for their body colour — no
        // per-frame deposit needed.  See startRadiationAtlas /
        // advanceRadiationAtlas / currentRadiationSnapshotIndex.
        if engineFieldMode == .radiation {
            if !radiationAtlasReady {
                advanceRadiationAtlas(into: commandBuffer)
            }
        } else {
            advancePhantom(into: commandBuffer, ticks: phantomTicksPerFrame)
        }

        let pingsBuffer: MTLBuffer? = pingDraws.isEmpty ? nil :
            device.makeBuffer(bytes: pingDraws,
                              length: pingDraws.count * MemoryLayout<ItLPingDraw>.stride,
                              options: .storageModeShared)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(aetherPipelineState)
        encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(backgroundTexture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Analytic disc in all three modes: E/B use closed-form LW
        // velocity field; R uses the low-β dipole radiation closed form
        // (see ItLLWEContext + the fieldMode==2 branch in the shader).
        if analyticDiscOn {
            encoder.setRenderPipelineState(lwePipelineState)
            encoder.setVertexBuffer(lweBuffer, offset: 0, index: 0)
            encoder.setFragmentBuffer(lweBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        if !teslons.isEmpty {
            encoder.setRenderPipelineState(loopPipelineState)
            encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
            let teslonsBuffer = device.makeBuffer(bytes: teslons, length: teslons.count * MemoryLayout<NorthLoop>.stride, options: .storageModeShared)!
            encoder.setVertexBuffer(teslonsBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: teslons.count)
        }

        if let pingsBuffer = pingsBuffer, !pingDraws.isEmpty {
            encoder.setRenderPipelineState(pingPipelineState)
            encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(pingsBuffer, offset: 0, index: 1)
            encoder.setFragmentBuffer(pingFragBuffer, offset: 0, index: 0)
            // Sensor binding depends on mode.
            //
            // E/B: bind sensorBuffer (last completed phantom) and
            // pulseSensorBuffer (current in-flight phantom).  The shader
            // picks pulseSensorBuffer where data exists, sensorBuffer
            // elsewhere, so wave transitions ride the wavefront.
            //
            // R: bind the snapshot for the current source phase to
            // buffer 1.  The MC per-ping rotational-impulse deposit
            // already encodes the radiation amplitude per cell, so a
            // single snapshot read suffices — no finite difference.
            //
            // E/B and pre-atlas R: bind sensorBuffer + pulseSensorBuffer.
            let primarySensor: MTLBuffer
            if engineFieldMode == .radiation && !radiationAtlasSnapshots.isEmpty {
                let idx = currentRadiationSnapshotIndex()
                primarySensor = radiationAtlasSnapshots[idx]
            } else {
                primarySensor = sensorBuffer
            }
            encoder.setFragmentBuffer(primarySensor, offset: 0, index: 1)
            encoder.setFragmentBuffer(pulseSensorBuffer, offset: 0, index: 2)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: pingDraws.count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
