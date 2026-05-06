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
}

private struct ItLLWEContext {
    var cameraPos: SIMD2<Float>
    var cameraBounds: SIMD2<Float>
    var beta: SIMD2<Float>
    var fieldMode: UInt32
    var _pad: UInt32 = 0
}

private struct ItLPingDraw {
    var position: SIMD2<Float>
    var cupola: SIMD2<Float>
    var velocity: SIMD2<Float>
}

private struct ItLPingFragCtx {
    var cameraPos: SIMD2<Float>
    var colormapExtent: Float
    var beta: Float
    var fullPingsOn: UInt32
    var magnitudeOn: UInt32
    var fieldMode: UInt32
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

// Toggle adjustments are decoupled from the animation: the slider's
// onChange only updates the analytic disc (renderer.velocity), and the
// model rebuild is deferred to slider release / toggle tap.  Each commit
// enqueues a single .rebuild — coalescing collapses any duplicates so
// the worker runs at most one phantom calc per intent change.
private enum ItLCommand: Equatable {
    case rebuild
}


private let kColormapMR = 128
private let kColormapMTheta = 240
private let kColormapExtent: Float = 700
private let kPulsePings: Int32 = 8500
// Slow-direction wavefront takes extent / ((1−β)·c) ticks; cap so the
// pulse buffer doesn't blow out at extreme β.
private let kMaxPulseTicks: Int = 1000

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
    // sensorBuffer / pulseSensorBuffer are swapped on commit — the worker
    // builds the new field in pulseSensorBuffer (no contention with the
    // live universe), then under universeLock atomically swaps the two
    // pointers so the next encoded draw frame samples the new field.
    private var sensorBuffer: MTLBuffer
    private var pulseSensorBuffer: MTLBuffer
    private let pulsePingsBuffer: MTLBuffer

    weak var view: MTKView?

    // User-intent settings.  velocity is updated live by the slider's
    // onChange — the analytic disc reads it directly, so it tracks the
    // thumb without touching the model.  The cupola/sensor rebuild only
    // happens on commit() (slider release, or magnitude/aberration tap).
    var velocity: Double = 0.70

    var pingsPerVolley: Int32 = 120
    var timeStepsPerVolley: Int = 12
    var autoOn: Bool = true
    // When on (default), each ping renders as body + cupola vector arrow
    // + head.  Off renders just the body dot.
    var fullPingsOn: Bool = true
    // When on (default), the analytic Liénard–Wiechert disc is drawn
    // beneath the pings as the reference target.  Off shows just the
    // cupola algorithm's output.
    var analyticDiscOn: Bool = true

    // Tap-to-toggle settings commit on every change.
    var magnitudeOn: Bool = true {
        didSet { commit() }
    }

    var aberrationOn: Bool = true {
        didSet { commit() }
    }

    // Field being verified: electric (rainbow LW-E) or magnetic (signed
    // diverging LW-B).  The analytic disc reads user-intent fieldMode
    // immediately; the cupola sensor field rebuilds via commit so the
    // ping coloring follows after the phantom calc finishes.
    var fieldMode: ItLFieldMode = .electric {
        didSet { commit() }
    }

    // Called by the velocity slider's onRelease (and on init) to submit
    // the current intent state to the worker for a phantom calc.
    func commit() {
        enqueue(.rebuild)
    }

    // Engine-applied state.  Worker writes; main draw + pulse read.
    // Initialised to match the user-intent defaults so the first
    // loadUniverse can configure the C engine without an enqueue.
    private var engineVelocity: Double = 0.70
    private var engineMagnitudeOn: Bool = true
    private var engineAberrationOn: Bool = true
    private var engineFieldMode: ItLFieldMode = .electric

    // Command queue + worker.
    private let workerQueue = DispatchQueue(label: "itl.worker", qos: .userInitiated)
    private let queueLock = NSLock()
    private var pending: [ItLCommand] = []
    private var workerActive: Bool = false

    // Universe access lock.  Held by main for each draw frame's universe
    // reads/tic, and by the worker only briefly at the end of a phantom
    // calc to swap settings + sensor buffer in.  The phantom calc itself
    // runs on a separate temporary universe and never touches the live
    // one, so the live model keeps animating without contention.
    private let universeLock = NSLock()

    private var universe: UnsafeMutablePointer<SCUniverse>?
    private var teslon: UnsafeMutablePointer<SCTeslon>?
    private var camera: UnsafeMutablePointer<SCCamera>?
    private var universeWidth: Double = 0
    private var universeHeight: Double = 0
    private var tickCount: Int = 0
    private var lastTickTime: CFTimeInterval = CACurrentMediaTime()

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
        // Drain any in-flight pulse so the worker can't outlive the universe.
        workerQueue.sync {}
        if let universe { SCUniverseRelease(universe) }
    }

// Universe =======================================================================================
    private func loadUniverse(width: Double, height: Double) {
        // Wait for any in-flight phantom calc to finish before tearing
        // down the live universe — the worker may be about to acquire
        // universeLock to swap in.
        workerQueue.sync {}
        universeLock.lock()
        defer { universeLock.unlock() }

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
        // Kick the initial phantom calc so the field is populated.
        DispatchQueue.main.async { [weak self] in self?.enqueue(.rebuild) }
    }

// Command queue ==================================================================================
    private func enqueue(_ cmd: ItLCommand) {
        queueLock.lock()
        coalesce(cmd)
        let kick = !workerActive && !pending.isEmpty
        if kick { workerActive = true }
        queueLock.unlock()
        if kick {
            workerQueue.async { [weak self] in self?.drain() }
        }
    }

    // Called with queueLock held.  Only one .rebuild is ever queued at
    // a time — the worker reads current intent state when it dequeues.
    private func coalesce(_ cmd: ItLCommand) {
        if !pending.contains(cmd) { pending.append(cmd) }
    }

    // Worker entry point.  Drains commands serially.
    private func drain() {
        while true {
            queueLock.lock()
            guard !pending.isEmpty else {
                workerActive = false
                queueLock.unlock()
                return
            }
            let cmd = pending.removeFirst()
            queueLock.unlock()
            apply(cmd)
        }
    }

    private func apply(_ cmd: ItLCommand) {
        // Capture intent state at the moment the worker dequeues.  Any
        // further user changes will arrive as their own .rebuild.
        let intentVelocity = self.velocity
        let intentMagnitudeOn = self.magnitudeOn
        let intentAberrationOn = self.aberrationOn
        let intentFieldMode = self.fieldMode
        let w = universeWidth
        let h = universeHeight
        guard w > 0, h > 0 else { return }

        // Phantom calc on a fresh, isolated universe — the live universe
        // is untouched, so main keeps animating at full frame rate.
        runPhantomCalc(width: w, height: h,
                       velocity: intentVelocity,
                       aberrationOn: intentAberrationOn,
                       magnitudeOn: intentMagnitudeOn,
                       fieldMode: intentFieldMode)

        // Brief swap-in.  Apply the new settings to the live universe
        // (auto-fire continues with the new emission/aether velocity)
        // and flip the sensor buffer so the next frame samples the new
        // field.  Lock contention with main is microseconds.
        universeLock.lock()
        if let live = self.universe {
            SCUniverseSetSpeed(live, intentVelocity)
            SCUniverseSetAberration(live, intentAberrationOn ? 1 : 0)
        }
        engineVelocity = intentVelocity
        engineMagnitudeOn = intentMagnitudeOn
        engineAberrationOn = intentAberrationOn
        engineFieldMode = intentFieldMode
        swap(&sensorBuffer, &pulseSensorBuffer)
        universeLock.unlock()
    }

    // Run the phantom calc on a fresh temporary SCUniverse and
    // accumulate the new field into pulseSensorBuffer.  The live
    // universe is untouched throughout.
    private func runPhantomCalc(width w: Double, height h: Double,
                                velocity: Double,
                                aberrationOn: Bool,
                                magnitudeOn: Bool,
                                fieldMode: ItLFieldMode) {
        let pulseUniverse = SCUniverseCreate(w, h)!
        defer { SCUniverseRelease(pulseUniverse) }
        SCUniverseSetC(pulseUniverse, 3.0)
        // Teslon is retained by the universe; we don't need the pointer.
        _ = SCUniverseCreateTeslon(pulseUniverse, w/2, h/2, 0, 0, 1.0, 1, 0)
        let pulseCamera = SCUniverseCreateCamera(pulseUniverse, w/2, h/2, 0, 0)!
        SCCameraSetWalls(pulseCamera, 0)
        SCUniverseSetAberration(pulseUniverse, aberrationOn ? 1 : 0)
        SCUniverseSetSpeed(pulseUniverse, velocity)

        SCUniversePing(pulseUniverse, kPulsePings)

        let sensorByteCount = kColormapMR * kColormapMTheta * MemoryLayout<UInt32>.size
        memset(pulseSensorBuffer.contents(), 0, sensorByteCount)

        guard let cmdBuf = commandQueue.makeCommandBuffer() else { return }
        let strideSize = MemoryLayout<ItLPingDraw>.stride
        let tgWidth = min(accumPipelineState.maxTotalThreadsPerThreadgroup, 64)

        // Slowest lab-frame ping (forward emission against aether) moves
        // at (1−β)c per tick; need that wavefront to reach extent.
        let slowSpeed = max(0.05, (1.0 - velocity) * 3.0)
        let pulseTicks = min(kMaxPulseTicks,
                             Int(ceil(Double(kColormapExtent) / slowSpeed)) + 4)

        for tick in 0..<pulseTicks {
            SCUniverseTic(pulseUniverse)
            let pingCount = Int(pulseUniverse.pointee.pingCount)
            if pingCount <= 0 { continue }

            let offset = tick * Int(kPulsePings) * strideSize
            let slot = pulsePingsBuffer.contents()
                .advanced(by: offset)
                .bindMemory(to: ItLPingDraw.self, capacity: pingCount)
            for i in 0..<pingCount {
                let p = pulseUniverse.pointee.pings[i]!
                slot[i] = ItLPingDraw(
                    position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                    cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                    velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y))
                )
            }

            var ctx = ItLAccumCtx(
                sourcePos: SIMD2<Float>(Float(pulseCamera.pointee.pos.x), Float(pulseCamera.pointee.pos.y)),
                aetherTranslation: SIMD2<Float>(-Float(velocity) * 3.0, 0),
                colormapExtent: kColormapExtent,
                c: 3.0,
                pingCount: UInt32(pingCount),
                magnitudeOn: magnitudeOn ? 1 : 0,
                fieldMode: fieldMode.rawValue
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

        cmdBuf.commit()
        cmdBuf.waitUntilCompleted()
    }

// Events =========================================================================================
    func onPing() {
        universeLock.lock()
        defer { universeLock.unlock() }
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

        // Lock contention with the worker is microseconds (only the
        // brief swap-in at the end of a phantom calc), so a plain lock
        // doesn't cause a noticeable hitch.
        universeLock.lock()
        defer { universeLock.unlock() }

        guard let universe, let camera else { return }

        tickCount += 1
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
            pingDraws.append(ItLPingDraw(
                position: SIMD2<Float>(Float(p.pointee.pos.x), Float(p.pointee.pos.y)),
                cupola: SIMD2<Float>(Float(p.pointee.cupola.x), Float(p.pointee.cupola.y)),
                velocity: SIMD2<Float>(Float(p.pointee.v.x), Float(p.pointee.v.y))
            ))
        }

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
        // the worker hasn't yet rebuilt the cupola field.
        var lweCtx = ItLLWEContext(
            cameraPos: cameraPos,
            cameraBounds: SIMD2<Float>(width, height),
            beta: SIMD2<Float>(Float(velocity), 0),
            fieldMode: fieldMode.rawValue
        )
        memcpy(lweBuffer.contents(), &lweCtx, MemoryLayout<ItLLWEContext>.size)

        // Cupola pings shade against the engine-applied state so what's
        // drawn matches the sensor field they sample from.
        var pingFragCtx = ItLPingFragCtx(
            cameraPos: cameraPos,
            colormapExtent: kColormapExtent,
            beta: Float(engineVelocity),
            fullPingsOn: fullPingsOn ? 1 : 0,
            magnitudeOn: engineMagnitudeOn ? 1 : 0,
            fieldMode: engineFieldMode.rawValue
        )
        memcpy(pingFragBuffer.contents(), &pingFragCtx, MemoryLayout<ItLPingFragCtx>.size)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // The sensor field is rebuilt off-thread by runPhantomCalc on
        // commit; nothing to deposit per frame.  This pings buffer is
        // purely for the visual flow.
        let pingsBuffer: MTLBuffer? = pingDraws.isEmpty ? nil :
            device.makeBuffer(bytes: pingDraws,
                              length: pingDraws.count * MemoryLayout<ItLPingDraw>.stride,
                              options: .storageModeShared)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(aetherPipelineState)
        encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(backgroundTexture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

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
            encoder.setFragmentBuffer(sensorBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: pingDraws.count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
