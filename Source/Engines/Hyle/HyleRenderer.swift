//
//  HyleRenderer.swift
//  Aexels
//
//  The bridge, rendered as the static entity it is (Joe's spec):
//
//  * FIXED STAGE — the two nodes never move on screen; r/L shows only
//    as disc size.  Inputs: v_A (direction + magnitude), v_B, r/L.
//  * OUTPUT — the frozen population of connecting signals between the
//    nodes at t = 0: each carrier's position plus its carried vectors
//    (translation, and cupola C = n-hat − beta).  From the transport's
//    perspective c ~ 0: the bridge is a standing structure.
//  * GENERATION — the closed-form retarded construction (validated in
//    the withdrawn scaffold, Physics 4befa69, re-verified at this seat
//    in Sims/Bridge): for constant velocities every connecting
//    signal's emission solves a quadratic intercept, so the corridor
//    populates directly — no warm-up integration.
//  * ABERRATION IS IN — the lead angle (emissions aim at the target's
//    future position), the cupola/translation split (each frozen
//    cupola axis passes through the other node's current position
//    while its translation points elsewhere), and Rule 3's
//    direction-dependent density (its fore/aft cancellation sets the
//    equal per-circuit rates; the two-lane counts come from the
//    transit times).
//  * The rendered bridge is the STARTING POINT: transport across it is
//    the next phase and is deliberately unspecified.  Mode/spin (BJFE)
//    enter conditionally later — they are not drawn here.
//

import Acheron
import MetalKit
import simd

struct HyleContext {
    var center: SIMD2<Float>
    var bounds: SIMD2<Float>
}

struct HyleLoop {
    var type: UInt32           // 0 node, 1 ping, 2 pong
    var extra: Float           // carriers: DESTINATION — 0 = bound for A (warm), 1 = bound for B (cool);
                               // node: radius.  The papers' own split: two bridges per pair, one per
                               // direction (BJFE S1), so each visible band is one solid hue.
    var position: SIMD2<Float>
    var dir: SIMD2<Float>      // translation (unit flight direction); node: unused
    var cupola: SIMD2<Float>   // carried cupola C = n-hat − beta; node: unused
}

class HyleRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let contextBuffer: MTLBuffer

    weak var view: MTKView?

    // The bridge model's state: (v_A, v_B, r/L) — speeds in units of
    // c, directions in degrees.  Stored initial conditions live in
    // HyleExperiment; touching any state variable directly makes the
    // configuration "custom".
    var betaA: Double = 0 { didSet { stateName = "custom" } }
    var thetaA: Double = 0 { didSet { stateName = "custom" } }
    var betaB: Double = 0 { didSet { stateName = "custom" } }
    var thetaB: Double = 0 { didSet { stateName = "custom" } }
    var ratio: Double = 0.08 { didSet { stateName = "custom" } }
    var stateName: String = "Static Pair"

    func apply(experiment: HyleExperiment) {
        betaA = experiment.betaA
        thetaA = experiment.thetaA
        betaB = experiment.betaB
        thetaB = experiment.thetaB
        ratio = experiment.ratio
        stateName = experiment.name
        loadUniverse()
    }

    // The frozen configuration's census, per circuit.
    private(set) var connectingPingsA: Int = 0
    private(set) var connectingPingsB: Int = 0
    private(set) var pongsToA: Int = 0
    private(set) var pongsToB: Int = 0

    private var loops: [HyleLoop] = []
    private var stageCenter: SIMD2<Float> = .zero
    private var stageBounds: SIMD2<Float> = .zero
    private var builtWidth: Double = 0
    private var builtHeight: Double = 0

    init?(view: MTKView) {
        self.view = view

        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = commandQueue
        view.device = device

        guard let contextBuffer = device.makeBuffer(length: MemoryLayout<HyleContext>.size, options: .storageModeShared) else { return nil }
        self.contextBuffer = contextBuffer

        let library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "hyleLoopVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "hyleLoopFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else { return nil }
        self.pipelineState = pipelineState

        super.init()

        view.delegate = self
    }

// The closed-form construction ====================================================================

    // Flight time tau >= 0 for a signal at speed c leaving a point
    // whose offset from the target is R0, the target moving at vT:
    // |R0 + vT tau| = c tau.  Exact (quadratic); c > |vT| guarantees
    // one non-negative root.
    private func interceptTau(R0: SIMD2<Double>, vT: SIMD2<Double>, c: Double) -> Double {
        let a: Double = simd_dot(vT, vT) - c*c
        let b: Double = simd_dot(R0, vT)
        let disc: Double = b*b - a*simd_dot(R0, R0)
        guard disc >= 0 else { return -1 }
        return (-b - disc.squareRoot()) / a
    }

    // SitD's pong rule: the ping's translation mirrored over its cupola
    // axis: v − 2 (v·C / C·C) C.  Speed is preserved.
    private func mirrored(_ v: SIMD2<Double>, over C: SIMD2<Double>) -> SIMD2<Double> {
        let c2: Double = simd_dot(C, C)
        guard c2 > 1e-18 else { return -v }
        return v - (2 * simd_dot(v, C) / c2) * C
    }

    // Build one circuit: source S emitting, target T answering.  The
    // corridor populates by uniform sampling in emission time — the
    // model's equal per-circuit capture rate (Rule 3's fore/aft
    // cancellation) makes uniform-in-t_e the steady-state measure, and
    // the two-lane counts then emerge from the windows' lengths.
    private func buildCircuit(S0: SIMD2<Double>, vS: SIMD2<Double>,
                              T0: SIMD2<Double>, vT: SIMD2<Double>,
                              r: Double, c: Double, circuit: Int,
                              into loops: inout [HyleLoop]) -> (pings: Int, pongs: Int) {
        let ratePerTic: Double = 0.55        // carriers per emission tic (visual scale)
        let maxPerLane: Int = 700

        // Ping window: emissions t_e in [tE0, 0] are in flight now —
        // tE0 is the emission arriving exactly now (tau = -tE0).
        let tau0: Double = interceptTau(R0: T0 - S0, vT: vT, c: c)
        guard tau0 > 0 else { return (0, 0) }
        let tE0: Double = -tau0

        var nPing: Int = 0
        var nPong: Int = 0

        let beta: SIMD2<Double> = vS / c
        let sight0: SIMD2<Double> = simd_normalize(T0 - S0)
        let perp0: SIMD2<Double> = SIMD2<Double>(-sight0.y, sight0.x)

        // Pings in flight.
        let pingWindow: Double = -tE0
        var kPing: Int = Int(pingWindow * ratePerTic)
        var stridePing: Double = 1
        if kPing > maxPerLane { stridePing = Double(kPing) / Double(maxPerLane); kPing = maxPerLane }
        for k in 0..<kPing {
            let u: Double = (Double(k) + 0.5) / Double(kPing)
            let tE: Double = tE0 * (1 - u)
            let b: Double = (fmod(Double(k) * 0.6180339887498949, 1.0) * 2 - 1) * 0.9 * r
            let P: SIMD2<Double> = S0 + vS * tE
            let aim: SIMD2<Double> = T0 + b * perp0
            let tau: Double = interceptTau(R0: aim + vT * tE - P, vT: vT, c: c)
            guard tau > 0, tE + tau >= 0 else { continue }
            let nHat: SIMD2<Double> = simd_normalize((aim + vT * (tE + tau)) - P)
            let pos: SIMD2<Double> = P + nHat * c * (-tE)
            let cupola: SIMD2<Double> = nHat - beta
            loops.append(HyleLoop(
                type: 1,
                extra: Float(1 - circuit),      // a ping is bound for the OTHER node
                position: SIMD2<Float>(Float(pos.x), Float(pos.y)),
                dir: SIMD2<Float>(Float(nHat.x), Float(nHat.y)),
                cupola: SIMD2<Float>(Float(cupola.x), Float(cupola.y))
            ))
            nPing += 1
            _ = stridePing
        }

        // Pongs in flight: emissions before tE0 whose ping already
        // landed (t_a <= 0) and whose answer is still flying.  March
        // backward from tE0 until answers have already returned.
        let maxBack: Double = 6 * (-tE0) + 4 * simd_length(T0 - S0) / c
        var kPong: Int = Int(maxBack * ratePerTic)
        var stridePong: Double = 1
        if kPong > 4 * maxPerLane { stridePong = Double(kPong) / Double(4 * maxPerLane); kPong = 4 * maxPerLane }
        var pongLoops: [HyleLoop] = []
        for k in 0..<kPong {
            let tE: Double = tE0 - (Double(k) + 0.5) * stridePong / ratePerTic
            let b: Double = (fmod(Double(k) * 0.6180339887498949 + 0.37, 1.0) * 2 - 1) * 0.9 * r
            let P: SIMD2<Double> = S0 + vS * tE
            let aim: SIMD2<Double> = T0 + b * perp0
            let tau: Double = interceptTau(R0: aim + vT * tE - P, vT: vT, c: c)
            guard tau > 0 else { continue }
            let tArr: Double = tE + tau
            guard tArr <= 0 else { continue }
            let nHat: SIMD2<Double> = simd_normalize((aim + vT * tArr) - P)
            let cupola: SIMD2<Double> = nHat - beta

            // Entry point on the target disc: impact parameter b gives
            // the entry normal at angle asin(b/r) off the facing
            // direction — the impact-parameter measure.
            let psi: Double = asin(max(-1, min(1, b / r)))
            let facing: SIMD2<Double> = -nHat
            let perpN: SIMD2<Double> = SIMD2<Double>(-facing.y, facing.x)
            let entryN: SIMD2<Double> = facing * cos(psi) + perpN * sin(psi)
            let H: SIMD2<Double> = (T0 + vT * tArr) + entryN * r

            let vPong: SIMD2<Double> = mirrored(nHat * c, over: cupola)
            let tauR: Double = interceptTau(R0: (S0 + vS * tArr) - H, vT: vS, c: c)
            guard tauR > 0, tArr + tauR >= 0 else { continue }
            let pos: SIMD2<Double> = H + vPong * (-tArr)
            let pongDir: SIMD2<Double> = simd_normalize(vPong)
            pongLoops.append(HyleLoop(
                type: 2,
                extra: Float(circuit),          // a pong returns to its circuit's source
                position: SIMD2<Float>(Float(pos.x), Float(pos.y)),
                dir: SIMD2<Float>(Float(pongDir.x), Float(pongDir.y)),
                cupola: SIMD2<Float>(Float(cupola.x), Float(cupola.y))
            ))
            nPong += 1
        }
        loops.append(contentsOf: pongLoops)
        return (nPing, nPong)
    }

    // Rebuild the frozen bridge from the current state.  (Named for
    // the controls tab's sake; there is no evolving universe here —
    // the construction is closed-form.)
    func loadUniverse() {
        guard let view else { return }
        let width: Double = view.drawableSize.width / view.contentScaleFactor
        let height: Double = view.drawableSize.height / view.contentScaleFactor
        guard width > 1, height > 1 else { return }
        builtWidth = width
        builtHeight = height

        let L: Double = min(width * 0.6, height * 0.8)
        let r: Double = max(ratio * L, 3)
        let c: Double = 2

        let A0: SIMD2<Double> = SIMD2<Double>(width/2 - L/2, height/2)
        let B0: SIMD2<Double> = SIMD2<Double>(width/2 + L/2, height/2)
        let radA: Double = thetaA * .pi/180
        let radB: Double = thetaB * .pi/180
        let vA: SIMD2<Double> = SIMD2<Double>(betaA * c * cos(radA), betaA * c * sin(radA))
        let vB: SIMD2<Double> = SIMD2<Double>(betaB * c * cos(radB), betaB * c * sin(radB))

        var built: [HyleLoop] = []
        let a: (pings: Int, pongs: Int) = buildCircuit(S0: A0, vS: vA, T0: B0, vT: vB, r: r, c: c, circuit: 0, into: &built)
        let b: (pings: Int, pongs: Int) = buildCircuit(S0: B0, vS: vB, T0: A0, vT: vA, r: r, c: c, circuit: 1, into: &built)
        connectingPingsA = a.pings
        pongsToA = a.pongs
        connectingPingsB = b.pings
        pongsToB = b.pongs

        // The nodes, last so they draw on top: fixed stage.
        for (P, v) in [(A0, vA), (B0, vB)] {
            let speed: Double = simd_length(v)
            let dir: SIMD2<Double> = speed > 1e-12 ? v / speed : SIMD2<Double>(0, 0)
            built.append(HyleLoop(
                type: 0,
                extra: Float(r),
                position: SIMD2<Float>(Float(P.x), Float(P.y)),
                dir: SIMD2<Float>(Float(dir.x * speed / c), Float(dir.y * speed / c)),
                cupola: .zero
            ))
        }

        loops = built
        stageCenter = SIMD2<Float>(Float(width/2), Float(height/2))
        stageBounds = SIMD2<Float>(Float(width), Float(height))
    }

// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        loadUniverse()
    }
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        let width: Double = view.drawableSize.width / view.contentScaleFactor
        let height: Double = view.drawableSize.height / view.contentScaleFactor
        if loops.isEmpty || abs(builtWidth - width) > 1 || abs(builtHeight - height) > 1 { loadUniverse() }

        var context: HyleContext = HyleContext(center: stageCenter, bounds: stageBounds)
        memcpy(contextBuffer.contents(), &context, MemoryLayout<HyleContext>.size)

        guard !loops.isEmpty,
              let loopsBuffer = device.makeBuffer(bytes: loops, length: loops.count * MemoryLayout<HyleLoop>.stride, options: .storageModeShared),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(contextBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(loopsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: loops.count)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
