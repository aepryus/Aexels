//
//  HyleRenderer.swift
//  Aexels
//
//  The bridge sim, per Joe's spec:
//
//  * FIXED STAGE — the nodes never move on screen; L/r shows as disc
//    size (L is pinned to the view).
//  * INPUTS — each node's velocity is a VECTOR ON THE NODE, picked up
//    and dragged; L/r is graduated 2^2 … 2^11 in the controls.
//  * RENDER — on generate, figure out how far to go back, place the
//    nodes there, and run the ACTUAL SIMULATOR (the Philippine sea —
//    rules as stated, aberration included) forward until the nodes
//    land on their stage positions at t = 0.  Plot the pings and the
//    pongs.  The plot is then FIXED: the frozen bridge.
//  * THE PONGS ARE FOAM — no cupolas rendered or needed; they are the
//    medium the coming transport phase will pass hyle through.
//

import Acheron
import MetalKit
import simd

struct HyleContext {
    var center: SIMD2<Float>
    var bounds: SIMD2<Float>
}

struct HyleLoop {
    var type: UInt32           // 0 node, 1 ping, 2 pong (foam), 3 velocity vector
    var extra: Float           // carriers: destination (0 = A warm, 1 = B cool); node: radius; vector: beta
    var position: SIMD2<Float>
    var dir: SIMD2<Float>      // vector/carrier direction (unit)
    var cupola: SIMD2<Float>   // unused (pongs are foam); kept for layout stability
}

class HyleRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let contextBuffer: MTLBuffer

    weak var view: MTKView?

    // The state: velocity vectors in units of c, and L/r.
    var vA: SIMD2<Double> = .zero { didSet { stateName = "custom" } }
    var vB: SIMD2<Double> = .zero { didSet { stateName = "custom" } }
    var lOverR: Double = 16 { didSet { stateName = "custom" } }
    var stateName: String = "Static Pair"

    // Densities — as in SitD.
    var pingsPerVolley: Int = 120
    var ticsPerVolley: Int = 12
    // pre-render: show the render PROCESS — the playback runs on
    // screen, the nodes walking onto their stage marks as the corridor
    // fills, freezing at t = 0.
    var showProcess: Bool = true
    // show pings: the generated ping field displayed behind the foam.
    var showPings: Bool = true { didSet { buildLoops() } }
    // The two bridges (one per direction), individually displayable.
    var showBridgeToA: Bool = true { didSet { buildLoops() } }
    var showBridgeToB: Bool = true { didSet { buildLoops() } }

    private(set) var playbackRemaining: Int = 0
    private var ticsPerFrame: Int = 1

    // The frozen configuration and its census.
    private(set) var pongsToA: Int = 0
    private(set) var pongsToB: Int = 0
    private(set) var pingsInFlight: Int = 0

    private var universe: UnsafeMutablePointer<PCUniverse>?
    private var nodeA: UnsafeMutablePointer<PCNode>?
    private var nodeB: UnsafeMutablePointer<PCNode>?

    private var carrierLoops: [HyleLoop] = []
    private var stageCenter: SIMD2<Float> = .zero
    private var stageBounds: SIMD2<Float> = .zero
    private var builtWidth: Double = 0
    private var builtHeight: Double = 0

    private let c: Double = 2

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
    deinit {
        if let universe { PCUniverseRelease(universe) }
    }

// Stage geometry ==================================================================================

    var stageWidth: Double { builtWidth }
    var stageHeight: Double { builtHeight }
    var L: Double { min(builtWidth * 0.6, builtHeight * 0.8) }
    var r: Double { max(L / lOverR, 0.5) }
    var A0: SIMD2<Double> { SIMD2<Double>(builtWidth/2 - L/2, builtHeight/2) }
    var B0: SIMD2<Double> { SIMD2<Double>(builtWidth/2 + L/2, builtHeight/2) }

    private func measureStage() {
        guard let view else { return }
        let width: Double = view.drawableSize.width / view.contentScaleFactor
        let height: Double = view.drawableSize.height / view.contentScaleFactor
        guard width > 1, height > 1 else { return }
        builtWidth = width
        builtHeight = height
        stageCenter = SIMD2<Float>(Float(width/2), Float(height/2))
        stageBounds = SIMD2<Float>(Float(width), Float(height))
    }

// Generate ========================================================================================

    func apply(experiment: HyleExperiment) {
        let radA: Double = experiment.thetaA * .pi/180
        let radB: Double = experiment.thetaB * .pi/180
        vA = SIMD2<Double>(experiment.betaA * cos(radA), experiment.betaA * sin(radA))
        vB = SIMD2<Double>(experiment.betaB * cos(radB), experiment.betaB * sin(radB))
        lOverR = experiment.lOverR
        stateName = experiment.name
        generate(process: showProcess)
    }

    // Go back far enough to fill both circuits, run the actual
    // simulator forward, and land the nodes on their stage positions
    // at t = 0.  The result is the frozen bridge.  With process on,
    // the playback runs on screen instead of silently.
    func generate(process: Bool = false) {
        measureStage()
        guard builtWidth > 1 else { return }

        if let universe { PCUniverseRelease(universe) }

        let betaMax: Double = min(max(simd_length(vA), simd_length(vB)), 0.9)
        let lookback: Int = min(8000, Int(2.5 * L / (c * (1 - betaMax)) + 2 * L / c) + 60)
        let T: Double = Double(lookback)

        // Start positions: displaced back along each track so the run
        // lands the nodes exactly on A0/B0 at t = 0.
        let vAp: SIMD2<Double> = vA * c        // lengths per tic
        let vBp: SIMD2<Double> = vB * c
        let aStart: SIMD2<Double> = A0 - vAp * T
        let bStart: SIMD2<Double> = B0 - vBp * T

        // The cull box follows the pair midpoint; size it to cover the
        // widest separation the run will see.
        let maxSepX: Double = max(abs(bStart.x - aStart.x), L)
        let maxSepY: Double = abs(bStart.y - aStart.y)
        let universe: UnsafeMutablePointer<PCUniverse> = PCUniverseCreate(maxSepX + builtWidth, maxSepY + builtHeight)
        PCUniverseSetC(universe, c)
        PCUniverseSetVolley(universe, Int32(pingsPerVolley), Int32(ticsPerVolley))

        nodeA = PCUniverseCreateNode(universe, aStart.x, aStart.y, r, 1, 1)
        nodeB = PCUniverseCreateNode(universe, bStart.x, bStart.y, r, 1, 1)
        PCUniverseSetNodeVelocity(universe, nodeA, vAp.x, vAp.y)
        PCUniverseSetNodeVelocity(universe, nodeB, vBp.x, vBp.y)

        self.universe = universe

        if process {
            playbackRemaining = lookback
            ticsPerFrame = max(1, lookback / 300)   // ~five seconds of watching
        } else {
            for _ in 0..<lookback { PCUniverseTic(universe) }
            playbackRemaining = 0
        }
        buildLoops()
    }

    // The frozen plot: pings faint, pongs as foam, nodes and their
    // velocity vectors on top.
    private func buildLoops() {
        var loops: [HyleLoop] = []
        var nPing: Int = 0
        var nPongA: Int = 0
        var nPongB: Int = 0

        // The nodes own their discs: carriers sitting under either
        // disc are culled from the display so nothing renders on top
        // of a node.  (Display only — the census counts everything.)
        var maskA: SIMD2<Double> = A0
        var maskB: SIMD2<Double> = B0
        if let nodeA, let nodeB {
            maskA = SIMD2<Double>(nodeA.pointee.pos.x, nodeA.pointee.pos.y)
            maskB = SIMD2<Double>(nodeB.pointee.pos.x, nodeB.pointee.pos.y)
        }
        let mask2: Double = (r * 1.15) * (r * 1.15)
        func underDisc(_ x: Double, _ y: Double) -> Bool {
            let dax: Double = x - maskA.x, day: Double = y - maskA.y
            if dax*dax + day*day < mask2 { return true }
            let dbx: Double = x - maskB.x, dby: Double = y - maskB.y
            return dbx*dbx + dby*dby < mask2
        }

        if let universe, let nodeA {
            for i: Int in 0..<Int(universe.pointee.pingCount) {
                let ping: UnsafeMutablePointer<PCPing> = universe.pointee.pings[i]!
                nPing += 1
                guard showPings else { continue }
                // A hidden bridge hides its feeding pings too: pongs → A
                // are the answers to A's own pings.
                let sourceIsA: Bool = ping.pointee.source == nodeA
                guard sourceIsA ? showBridgeToA : showBridgeToB else { continue }
                guard !underDisc(ping.pointee.pos.x, ping.pointee.pos.y) else { continue }
                loops.append(HyleLoop(
                    type: 1,
                    extra: sourceIsA ? 1 : 0,
                    position: SIMD2<Float>(Float(ping.pointee.pos.x), Float(ping.pointee.pos.y)),
                    dir: SIMD2<Float>(Float(ping.pointee.dir.x), Float(ping.pointee.dir.y)),
                    cupola: .zero
                ))
            }
            for i: Int in 0..<Int(universe.pointee.pongCount) {
                let pong: UnsafeMutablePointer<PCPong> = universe.pointee.pongs[i]!
                let boundForA: Bool = pong.pointee.target == nodeA
                if boundForA { nPongA += 1 } else { nPongB += 1 }
                guard boundForA ? showBridgeToA : showBridgeToB else { continue }
                guard !underDisc(pong.pointee.pos.x, pong.pointee.pos.y) else { continue }
                loops.append(HyleLoop(
                    type: 2,
                    extra: boundForA ? 0 : 1,
                    position: SIMD2<Float>(Float(pong.pointee.pos.x), Float(pong.pointee.pos.y)),
                    dir: SIMD2<Float>(Float(pong.pointee.dir.x), Float(pong.pointee.dir.y)),
                    cupola: .zero
                ))
            }
        }

        pingsInFlight = nPing
        pongsToA = nPongA
        pongsToB = nPongB
        carrierLoops = loops
    }

    // The stage dressing rebuilt without touching the frozen carriers —
    // used live while a velocity vector is being dragged.  During the
    // render process, the nodes draw where they ARE, walking onto
    // their stage marks.
    private func stageLoops() -> [HyleLoop] {
        var pairs: [(SIMD2<Double>, SIMD2<Double>)] = [(A0, vA), (B0, vB)]
        if playbackRemaining > 0, let nodeA, let nodeB {
            pairs = [
                (SIMD2<Double>(nodeA.pointee.pos.x, nodeA.pointee.pos.y), vA),
                (SIMD2<Double>(nodeB.pointee.pos.x, nodeB.pointee.pos.y), vB)
            ]
        }
        var loops: [HyleLoop] = []
        for (P, v) in pairs {
            loops.append(HyleLoop(
                type: 0,
                extra: Float(r),
                position: SIMD2<Float>(Float(P.x), Float(P.y)),
                dir: .zero,
                cupola: .zero
            ))
            let beta: Double = simd_length(v)
            if beta > 0.01 {
                loops.append(HyleLoop(
                    type: 3,
                    extra: Float(beta),
                    position: SIMD2<Float>(Float(P.x), Float(P.y)),
                    dir: SIMD2<Float>(Float(v.x/beta), Float(v.y/beta)),
                    cupola: .zero
                ))
            }
        }
        return loops
    }

// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        generate(process: false)
    }
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        let width: Double = view.drawableSize.width / view.contentScaleFactor
        if builtWidth < 1 || abs(builtWidth - width) > 1 { generate(process: false) }

        // The render process, on screen: advance the playback and show
        // it, freezing when the nodes land on their marks at t = 0.
        if playbackRemaining > 0, let universe {
            let k: Int = min(ticsPerFrame, playbackRemaining)
            for _ in 0..<k { PCUniverseTic(universe) }
            playbackRemaining -= k
            buildLoops()
        }

        var context: HyleContext = HyleContext(center: stageCenter, bounds: stageBounds)
        memcpy(contextBuffer.contents(), &context, MemoryLayout<HyleContext>.size)

        let loops: [HyleLoop] = carrierLoops + stageLoops()
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
