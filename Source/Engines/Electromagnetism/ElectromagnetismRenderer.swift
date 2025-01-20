//
//  ElectromagnetismRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import MetalKit
import simd

struct MetalUniverse {
    var bounds: SIMD2<Float>
    var cameraPos: SIMD2<Float>
};

struct MetalObject {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var type: Int
    var speed: Float
    var orient: Float
    var cupola: Float
    var hyle: Float
    var pad1: Float
    var pad2: Float
};

class ElectromagnetismRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    
    var universe: UnsafeMutablePointer<NCUniverse>
    var camera: UnsafeMutablePointer<NCCamera>
    
    private var position: SIMD2<Float>
    private var lastUpdateTime: CFTimeInterval
    
    private let universeBuffer: MTLBuffer
    private var initialized: Bool = false
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        metalView.device = device
        
        position = SIMD2<Float>(0, 0)
        lastUpdateTime = CACurrentMediaTime()
        
        guard let universeBuffer = device.makeBuffer(length: MemoryLayout<Universe>.size, options: .storageModeShared) else { return nil }
        
        self.universeBuffer = universeBuffer
        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "em_vertex_shader")
        let fragmentFunction = library.makeFunction(name: "em_fragment_shader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            return nil
        }
        self.pipelineState = pipelineState
        
        universe = NCUniverseCreate(metalView.width, metalView.height)
        NCUniverseCreateTeslon(universe, 360, 240, 0.35, 0.3, 1)
        NCUniverseCreateTeslon(universe, 360, 400, -0.35, 0.3, 1)
        camera = NCUniverseCreateCamera(universe, metalView.width/2, metalView.height/2, velocity, 0)
        
        super.init()
        metalView.delegate = self
    }
    
    var velocity: Double = 0 {
        didSet { NCUniverseSetSpeed(universe, velocity) }
    }
    
// Events ==========================================================================================
    func onPing() { NCUniversePing(universe, 1000) }
    
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        
        NCUniverseTic(universe)
        
        var metalUniverse: MetalUniverse = MetalUniverse(bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)), cameraPos: SIMD2<Float>(Float(camera.pointee.pos.x), Float(camera.pointee.pos.y)))
        memcpy(universeBuffer.contents(), &metalUniverse, MemoryLayout<MetalUniverse>.size)
        
        var objects: [MetalObject] = []
        var pings: [MetalObject] = []

        for i: Int in 0..<Int(universe.pointee.teslonCount) {
            let teslon: UnsafeMutablePointer<NCTeslon> = universe.pointee.teslons[i]!
            let object: MetalObject = MetalObject(
                position: SIMD2<Float>(Float(teslon.pointee.pos.x), Float(teslon.pointee.pos.y)),
                velocity: SIMD2<Float>(0, 0),
                type: 0,
                speed: 0,
                orient: 0,
                cupola: 0,
                hyle: Float(teslon.pointee.iHyle),
                pad1: 0,
                pad2: 0
            )
            objects.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.pingCount) {
            let ping: UnsafeMutablePointer<NCPing> = universe.pointee.pings[i]!
            let object: MetalObject = MetalObject(
                position: SIMD2<Float>(Float(ping.pointee.pos.x), Float(ping.pointee.pos.y)),
                velocity: SIMD2<Float>(0, 0),
                type: 1,
                speed: 0,
                orient: 0,
                cupola: 0,
                hyle: 0,
                pad1: 0,
                pad2: 0
            )
            pings.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.pongCount) {
            let pong: UnsafeMutablePointer<NCPong> = universe.pointee.pongs[i]!
            let object: MetalObject = MetalObject(
                position: SIMD2<Float>(Float(pong.pointee.pos.x), Float(pong.pointee.pos.y)),
                velocity: SIMD2<Float>(0, 0),
                type: 2,
                speed: 0,
                orient: 0,
                cupola: 0,
                hyle: 0,
                pad1: 0,
                pad2: 0
            )
            objects.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.photonCount) {
            let photon: UnsafeMutablePointer<NCPhoton> = universe.pointee.photons[i]!
            let object: MetalObject = MetalObject(
                position: SIMD2<Float>(Float(photon.pointee.pos.x), Float(photon.pointee.pos.y)),
                velocity: SIMD2<Float>(0, 0),
                type: 3,
                speed: 0,
                orient: 0,
                cupola: 0,
                hyle: Float(photon.pointee.hyle),
                pad1: 0,
                pad2: 0
            )
            objects.append(object)
        }
        
        let objectsBuffer = device.makeBuffer(bytes: objects, length: objects.count * MemoryLayout<MetalObject>.stride, options: .storageModeShared)!
        let pingsBuffer: MTLBuffer? = pings.count == 0 ? nil : device.makeBuffer(bytes: pings, length: pings.count * MemoryLayout<MetalObject>.stride, options: .storageModeShared)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(universeBuffer, offset: 0, index: 0)
        if let pingsBuffer {
            renderEncoder.setVertexBuffer(pingsBuffer, offset: 0, index: 1)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: pings.count)
        }
        renderEncoder.setVertexBuffer(objectsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: objects.count)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
