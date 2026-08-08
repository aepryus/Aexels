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
    var extra: Float           // node: radius; pong: 0 => toward A (warm), 1 => toward B (cool)
    var position: SIMD2<Float>
    var dir: SIMD2<Float>
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

    var census: (toA: Int, toB: Int) {
        guard let universe, let nodeA, let nodeB else { return (0, 0) }
        return (Int(PCUniverseCensus(universe, nodeA)), Int(PCUniverseCensus(universe, nodeB)))
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
        nodeA = PCUniverseCreateNode(universe, width/2 - L/2, height/2, a, 1, 1)
        nodeB = PCUniverseCreateNode(universe, width/2 + L/2, height/2, a, 1, 1)

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
        guard let universe, let nodeA else { return }

        PCUniverseTic(universe)

        var context: HyleContext = HyleContext(
            center: SIMD2<Float>(Float(universe.pointee.width/2), Float(universe.pointee.height/2)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height))
        )
        memcpy(contextBuffer.contents(), &context, MemoryLayout<HyleContext>.size)

        var loops: [HyleLoop] = []

        for i: Int in 0..<Int(universe.pointee.pingCount) {
            let ping: UnsafeMutablePointer<PCPing> = universe.pointee.pings[i]!
            loops.append(HyleLoop(
                type: 1,
                extra: 0,
                position: SIMD2<Float>(Float(ping.pointee.pos.x), Float(ping.pointee.pos.y)),
                dir: SIMD2<Float>(Float(ping.pointee.dir.x), Float(ping.pointee.dir.y))
            ))
        }
        for i: Int in 0..<Int(universe.pointee.pongCount) {
            let pong: UnsafeMutablePointer<PCPong> = universe.pointee.pongs[i]!
            loops.append(HyleLoop(
                type: 2,
                extra: pong.pointee.target == nodeA ? 0 : 1,
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
                dir: SIMD2<Float>(0, 0)
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
