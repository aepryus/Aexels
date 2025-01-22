//
//  ElectromagnetismRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import MetalKit
import simd

struct NorthCamera {
    var position: SIMD2<Float>
    var bounds: SIMD2<Float>
    var velocity: SIMD2<Float>
};

struct NorthLoop {
    var type: Int
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var cupola: SIMD2<Float>
    var hyle: Float
};

class ElectromagnetismRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    
    var universe: UnsafeMutablePointer<NCUniverse>
    var camera: UnsafeMutablePointer<NCCamera>
    
    private var position: SIMD2<Float>
    private var lastUpdateTime: CFTimeInterval
    
    private let cameraBuffer: MTLBuffer
    private var initialized: Bool = false
    
    private let backgroundTexture: MTLTexture
    private let backgroundPipelineState: MTLRenderPipelineState
    
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
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<NorthCamera>.size, options: .storageModeShared) else { return nil }
        
        self.cameraBuffer = cameraBuffer
        
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
        
        let backgroundVertexFunction = library.makeFunction(name: "northBackVertexShader")
        let backgroundFragmentFunction = library.makeFunction(name: "northBackFragmentShader")
        
        let backgroundPipelineDescriptor = MTLRenderPipelineDescriptor()
        backgroundPipelineDescriptor.vertexFunction = backgroundVertexFunction
        backgroundPipelineDescriptor.fragmentFunction = backgroundFragmentFunction
        backgroundPipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        guard let backgroundPipelineState = try? device.makeRenderPipelineState(descriptor: backgroundPipelineDescriptor) else { return nil }
        self.backgroundPipelineState = backgroundPipelineState
        
        // Create texture from your existing UIImage
        let image = Engine.renderHex(size: CGSize(width: metalView.bounds.width, height: metalView.bounds.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let backgroundTexture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB : false]) else { return nil }
        self.backgroundTexture = backgroundTexture

        super.init()
        metalView.delegate = self
    }
    
    var velocity: Double = 0 {
        didSet { NCUniverseSetSpeed(universe, velocity) }
    }
    
// Events ==========================================================================================
    func onPing() { NCUniversePing(universe, 12*40) }
    func onPong() { NCUniversePong(universe) }
    
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        
        NCUniverseTic(universe)
        
        var camera: NorthCamera = NorthCamera(
            position: SIMD2<Float>(Float(camera.pointee.pos.x), Float(camera.pointee.pos.y)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)),
            velocity: SIMD2<Float>(Float(camera.pointee.v.x), Float(camera.pointee.v.y))
        )
        memcpy(cameraBuffer.contents(), &camera, MemoryLayout<NorthCamera>.size)
        
        var objects: [NorthLoop] = []
        var pings: [NorthLoop] = []

        for i: Int in 0..<Int(universe.pointee.teslonCount) {
            let teslon: UnsafeMutablePointer<NCTeslon> = universe.pointee.teslons[i]!
            let object: NorthLoop = NorthLoop(
                type: 0,
                position: SIMD2<Float>(Float(teslon.pointee.pos.x), Float(teslon.pointee.pos.y)),
                velocity: SIMD2<Float>(0, 0),
                cupola: SIMD2<Float>(0, 0),
                hyle: Float(teslon.pointee.iHyle)
            )
            objects.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.pingCount) {
            let ping: UnsafeMutablePointer<NCPing> = universe.pointee.pings[i]!
            let object: NorthLoop = NorthLoop(
                type: 1,
                position: SIMD2<Float>(Float(ping.pointee.pos.x), Float(ping.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(ping.pointee.v.x), Float(ping.pointee.v.y)),
                cupola: SIMD2<Float>(Float(ping.pointee.cupola.x), Float(ping.pointee.cupola.y)),
                hyle: 0
            )
            pings.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.pongCount) {
            let pong: UnsafeMutablePointer<NCPong> = universe.pointee.pongs[i]!
            let object: NorthLoop = NorthLoop(
                type: 2,
                position: SIMD2<Float>(Float(pong.pointee.pos.x), Float(pong.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(pong.pointee.v.x), Float(pong.pointee.v.y)),
                cupola: SIMD2<Float>(Float(pong.pointee.cupola.x), Float(pong.pointee.cupola.y)),
                hyle: 0
            )
            objects.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.photonCount) {
            let photon: UnsafeMutablePointer<NCPhoton> = universe.pointee.photons[i]!
            let object: NorthLoop = NorthLoop(
                type: 3,
                position: SIMD2<Float>(Float(photon.pointee.pos.x), Float(photon.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(photon.pointee.v.x), Float(photon.pointee.v.y)),
                cupola: SIMD2<Float>(Float(photon.pointee.cupola.x), Float(photon.pointee.cupola.y)),
                hyle: Float(photon.pointee.hyle)
            )
            objects.append(object)
        }
        
        let objectsBuffer = device.makeBuffer(bytes: objects, length: objects.count * MemoryLayout<NorthLoop>.stride, options: .storageModeShared)!
        let pingsBuffer: MTLBuffer? = pings.count == 0 ? nil : device.makeBuffer(bytes: pings, length: pings.count * MemoryLayout<NorthLoop>.stride, options: .storageModeShared)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(backgroundPipelineState)
        renderEncoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
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
