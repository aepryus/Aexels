//
//  HyleRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 8/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//
//  Demo 0: the static pong bridge.  Two nodes; the only physics is
//  emit, fly, capture, respond (Philippine sea).  The standing
//  in-flight pong population between the nodes is the bridge — two
//  directed cones, each broad (~a) at its origin face and converging
//  on the far node, emerging rather than drawn.
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
    var extra: Float           // node: radius; pong: 1 => plus channel (warm), 0 => minus (cool)
    var position: SIMD2<Float>
    var dir: SIMD2<Float>      // node: m-hat; pong: flight direction
}

// The bridge cases of Sims/Bridge, live: velocities in units of c.
struct HylePreset {
    let name: String
    let vA: (Double, Double)
    let vB: (Double, Double)
}

class HyleRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let contextBuffer: MTLBuffer

    weak var view: MTKView?

    var universe: UnsafeMutablePointer<PCUniverse>?
    var nodeA: UnsafeMutablePointer<PCNode>?
    var nodeB: UnsafeMutablePointer<PCNode>?

    static let presets: [HylePreset] = [
        HylePreset(name: "static pair",            vA: (0, 0),      vB: (0, 0)),
        HylePreset(name: "co-moving ∥  β 0.6",     vA: (0.6, 0),    vB: (0.6, 0)),
        HylePreset(name: "co-moving ⊥  β 0.6",     vA: (0, 0.6),    vB: (0, 0.6)),
        HylePreset(name: "head-on  β 0.3 each",    vA: (0.3, 0),    vB: (-0.3, 0)),
    ]
    private(set) var presetIndex: Int = 0
    var preset: HylePreset { HyleRenderer.presets[presetIndex] }

    func nextPreset() {
        presetIndex = (presetIndex + 1) % HyleRenderer.presets.count
        loadUniverse()
    }

    var census: (toA: Int, toB: Int) {
        guard let universe, let nodeA, let nodeB else { return (0, 0) }
        return (Int(PCUniverseCensus(universe, nodeA)), Int(PCUniverseCensus(universe, nodeB)))
    }

    // The stake-setter's angle chi between each node's mode axis and its
    // incoming beam (the direction toward the other node).  The split of
    // captures converges to the Born weights (1 +/- cos chi)/2 in the
    // point-node limit; at finite a/L the exact target comes from
    // quadrature over the capture arc (verified against the headless
    // build in Sims/PongBridge, stage 4 — agreement ~1e-5).
    var chiA: Double = 60 * .pi/180
    var chiB: Double = 120 * .pi/180
    private var predictedA: Double = .nan   // exact target; NaN when the pair moves
    private var predictedB: Double = .nan   // (the static quadrature does not apply)

    struct Stake { var chi: Double; var plus: Int; var minus: Int; var predicted: Double
        var measured: Double { plus + minus == 0 ? 0 : Double(plus)/Double(plus + minus) }
        var born: Double { (1 + cos(chi))/2 }
    }
    var stakes: (a: Stake, b: Stake) {
        guard let nodeA, let nodeB else { return (Stake(chi: chiA, plus: 0, minus: 0, predicted: predictedA), Stake(chi: chiB, plus: 0, minus: 0, predicted: predictedB)) }
        return (Stake(chi: chiA, plus: Int(nodeA.pointee.plusCaptures), minus: Int(nodeA.pointee.minusCaptures), predicted: predictedA),
                Stake(chi: chiB, plus: Int(nodeB.pointee.plusCaptures), minus: Int(nodeB.pointee.minusCaptures), predicted: predictedB))
    }

    // Exact finite-L stake: quadrature over the capture arc — emission
    // angle uniform (isotropic point source), entry point exact,
    // classified by sign(n-hat . m-hat).
    private func stakeTarget(L: Double, a: Double, chi: Double) -> Double {
        let mx: Double = cos(chi), my: Double = sin(chi)
        let phiMax: Double = asin(a/L)
        let N: Int = 200000
        var plus: Int = 0
        for i in 0..<N {
            let phi: Double = phiMax * (2.0*(Double(i) + 0.5)/Double(N) - 1.0)
            let st: Double = L*sin(phi)
            let entry: Double = L*cos(phi) - sqrt(a*a - st*st)
            let ex: Double = entry*cos(phi), ey: Double = entry*sin(phi)
            let nx: Double = (ex - L)/a, ny: Double = ey/a
            if (-nx)*mx + (-ny)*my > 0 { plus += 1 }
        }
        return Double(plus)/Double(N)
    }

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

    func loadUniverse() {
        guard let view else { return }
        if let universe { PCUniverseRelease(universe) }

        let width: Double = view.drawableSize.width / view.contentScaleFactor
        let height: Double = view.drawableSize.height / view.contentScaleFactor
        guard width > 1, height > 1 else { return }

        let universe: UnsafeMutablePointer<PCUniverse> = PCUniverseCreate(width, height)
        PCUniverseSetC(universe, 2)
        PCUniverseSetRho0(universe, 36)

        let a: Double = 18
        let L: Double = min(width * 0.6, height * 0.8)
        let c: Double = 2
        nodeA = PCUniverseCreateNode(universe, width/2 - L/2, height/2, a, 1, 1)
        nodeB = PCUniverseCreateNode(universe, width/2 + L/2, height/2, a, 1, 1)

        PCUniverseSetNodeVelocity(universe, nodeA, preset.vA.0 * c, preset.vA.1 * c)
        PCUniverseSetNodeVelocity(universe, nodeB, preset.vB.0 * c, preset.vB.1 * c)

        // m-hat = the incoming beam direction (toward the other node)
        // rotated by chi.  A's beam arrives along +x, B's along -x.
        PCNodeSetMode(nodeA, cos(chiA), sin(chiA))
        PCNodeSetMode(nodeB, -cos(chiB), -sin(chiB))

        // The exact stake target is the static-geometry quadrature; it
        // applies only when the pair is at rest.  For moving cases the
        // scoreboard shows the measured split alone — what the moving
        // interrogation does to the stake is a measurement, not yet a
        // prediction, at this seat.
        let isStatic: Bool = preset.vA == (0, 0) && preset.vB == (0, 0)
        predictedA = isStatic ? stakeTarget(L: L, a: a, chi: chiA) : .nan
        predictedB = isStatic ? stakeTarget(L: L, a: a, chi: chiB) : .nan

        self.universe = universe
    }

// Events ==========================================================================================
    func onReset() {
        guard let universe else { return }
        PCUniverseReset(universe)
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
        if universe == nil || abs((universe?.pointee.width ?? 0) - width) > 1 || abs((universe?.pointee.height ?? 0) - height) > 1 { loadUniverse() }
        guard let universe else { return }

        PCUniverseTic(universe)

        // The camera rides the pair: their midpoint stays centered and
        // the medium (the ping traffic) streams past — aberration and
        // the two-lane corridor become visible.
        var cx: Double = universe.pointee.width/2
        var cy: Double = universe.pointee.height/2
        if let nodeA, let nodeB {
            cx = (nodeA.pointee.pos.x + nodeB.pointee.pos.x)/2
            cy = (nodeA.pointee.pos.y + nodeB.pointee.pos.y)/2
        }
        var context: HyleContext = HyleContext(
            center: SIMD2<Float>(Float(cx), Float(cy)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height))
        )
        memcpy(contextBuffer.contents(), &context, MemoryLayout<HyleContext>.size)

        var loops: [HyleLoop] = []

        for i: Int in 0..<Int(universe.pointee.pingCount) {
            let ping: UnsafeMutablePointer<PCPing> = universe.pointee.pings[i]!
            loops.append(HyleLoop(
                type: 1,
                extra: ping.pointee.source == nodeA ? 0 : 1,
                position: SIMD2<Float>(Float(ping.pointee.pos.x), Float(ping.pointee.pos.y)),
                dir: SIMD2<Float>(Float(ping.pointee.dir.x), Float(ping.pointee.dir.y))
            ))
        }
        for i: Int in 0..<Int(universe.pointee.pongCount) {
            let pong: UnsafeMutablePointer<PCPong> = universe.pointee.pongs[i]!
            loops.append(HyleLoop(
                type: 2,
                extra: Float(pong.pointee.channel),
                position: SIMD2<Float>(Float(pong.pointee.pos.x), Float(pong.pointee.pos.y)),
                dir: SIMD2<Float>(Float(pong.pointee.dir.x), Float(pong.pointee.dir.y))
            ))
        }
        for i: Int in 0..<Int(universe.pointee.nodeCount) {
            let node: UnsafeMutablePointer<PCNode> = universe.pointee.nodes[i]!
            loops.append(HyleLoop(
                type: 0,
                extra: Float(node.pointee.a),
                position: SIMD2<Float>(Float(node.pointee.pos.x), Float(node.pointee.pos.y)),
                dir: SIMD2<Float>(Float(node.pointee.mode.x), Float(node.pointee.mode.y))
            ))
        }

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
