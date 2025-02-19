//
//  GravityRenderer.swift
//  Aexels
//
//  Created by Joe Charlier with Grok on 2/19/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import simd

struct CaspianCamera {
    var position: SIMD2<Float>      // 8 bytes
    var bounds: SIMD2<Float>        // 8 bytes
    var hexBounds: SIMD2<Float>     // 8 bytes
    var velocity: SIMD2<Float>      // 8 bytes
    var hexWidth: Float             // 4 bytes
    var padding: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)  // 12 bytes
}

struct CaspianLoop {
    var type: Int32
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var hyle: Float
}

class GravityRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let backgroundPipelineState: MTLRenderPipelineState
    
    var universe: UnsafeMutablePointer<CSUniverse>?
    var camera: UnsafeMutablePointer<CSCamera>?
    
    private let cameraBuffer: MTLBuffer
    private let centerBuffer: MTLBuffer
    private let hyleBuffer: MTLBuffer
    private var backgroundTexture: MTLTexture
    
    weak var view: MTKView?
    var t: Int = 0
    
    init?(view: MTKView) {
        self.view = view
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        view.device = device
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<CaspianCamera>.size, options: .storageModeShared),
              let centerBuffer = device.makeBuffer(length: MemoryLayout<SIMD2<Float>>.size, options: .storageModeShared),
              let hyleBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: .storageModeShared) else {
            return nil
        }
        self.cameraBuffer = cameraBuffer
        self.centerBuffer = centerBuffer
        self.hyleBuffer = hyleBuffer
        
        guard let library = device.makeDefaultLibrary() else { return nil }
        
        // Loop Pipeline
        let vertexFunction = library.makeFunction(name: "caspianLoopVertexShader")
        let fragmentFunction = library.makeFunction(name: "caspianLoopFragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
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
        
        // Background Pipeline
        let backgroundVertexFunction = library.makeFunction(name: "caspianAetherVertexShader")
        let backgroundFragmentFunction = library.makeFunction(name: "caspianAetherFragmentShader")
        let backgroundPipelineDescriptor = MTLRenderPipelineDescriptor()
        backgroundPipelineDescriptor.vertexFunction = backgroundVertexFunction
        backgroundPipelineDescriptor.fragmentFunction = backgroundFragmentFunction
        backgroundPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        guard let backgroundPipelineState = try? device.makeRenderPipelineState(descriptor: backgroundPipelineDescriptor) else { return nil }
        self.backgroundPipelineState = backgroundPipelineState
        
        let image = Engine.renderHex(size: CGSize(width: Screen.height, height: Screen.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let backgroundTexture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB : false]) else { return nil }
        self.backgroundTexture = backgroundTexture
        
        super.init()
        view.delegate = self
        
        // Initialize Universe
        let width = view.drawableSize.width / view.contentScaleFactor
        let height = view.drawableSize.height / view.contentScaleFactor
        universe = CSUniverseCreate(width, height)
        camera = CSUniverseCreateCamera(universe, width / 2, height / 2)
        
        // Planet Core: 100 teslons
        for i in 0..<100 {
            CSUniverseCreateTeslon(universe, width / 2 + Double(i % 10) * 10 - 45, height / 2 + Double(i / 10) * 10 - 45, 5.972e22)  // Earth mass / 100
        }
        // Test teslon
        CSUniverseCreateTeslon(universe, width / 2 + 1000, height / 2, 1e20)
    }
    
    deinit {
        if let universe = universe { CSUniverseRelease(universe) }
    }
    
    // MTKViewDelegate =============================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let universe else { return }
        let width = size.width / view.contentScaleFactor
        let height = size.height / view.contentScaleFactor
        universe.pointee.width = width
        universe.pointee.height = height
        camera?.pointee.width = width
        camera?.pointee.height = height
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let universe = universe,
              let camera = camera else { return }
        
        t += 1
        CSUniverseTic(universe)
        
        // Debug: Log every 100 frames
//        if t % 100 == 0 {
//            print("Frame \(t)")
//            print("Render pass clear color: \(String(describing: renderPassDescriptor.colorAttachments[0].clearColor))")
//            print("MTKView clear color: \(view.clearColor)")
//            
//            print("Camera: \(caspianCamera)")
//            print("Center: \(center)")
//            print("Total Hyle: \(total_hyle)")
//            print("Teslon count: \(universe.pointee.teslonCount)")
//            for i in 0..<Int(universe.pointee.teslonCount) {
//                let teslon = universe.pointee.teslons[i]!
//                print("Teslon \(i): pos=\(teslon.pointee.pos.x), \(teslon.pointee.pos.y), hyle=\(teslon.pointee.hyle)")
//            }
//            print("Loops count: \(loops.count)")
//        }
        
        var total_hyle: Float = 0
        var center = SIMD2<Float>(0, 0)
        for i in 0..<Int(universe.pointee.teslonCount) {
            let teslon = universe.pointee.teslons[i]!
            total_hyle += Float(teslon.pointee.hyle)
            center.x += Float(teslon.pointee.pos.x) * Float(teslon.pointee.hyle)
            center.y += Float(teslon.pointee.pos.y) * Float(teslon.pointee.hyle)
        }
        center /= total_hyle
        
        var caspianCamera = CaspianCamera(
            position: SIMD2<Float>(Float(camera.pointee.pos.x), Float(camera.pointee.pos.y)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)),
            hexBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height)),
            velocity: SIMD2<Float>(Float(camera.pointee.v.x), Float(camera.pointee.v.y)),
            hexWidth: Float(10.0 * Screen.s * 3)
        )
        memcpy(cameraBuffer.contents(), &caspianCamera, MemoryLayout<CaspianCamera>.size)
        memcpy(centerBuffer.contents(), &center, MemoryLayout<SIMD2<Float>>.size)
        memcpy(hyleBuffer.contents(), &total_hyle, MemoryLayout<Float>.size)
        
        var loops: [CaspianLoop] = []
        for i in 0..<Int(universe.pointee.teslonCount) {
            let teslon = universe.pointee.teslons[i]!
            let loop = CaspianLoop(
                type: 0,
                position: SIMD2<Float>(Float(teslon.pointee.pos.x), Float(teslon.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(teslon.pointee.v.x), Float(teslon.pointee.v.y)),
                hyle: Float(teslon.pointee.hyle)
            )
            loops.append(loop)
        }
        
        let loopsBuffer = device.makeBuffer(bytes: loops, length: loops.count * MemoryLayout<CaspianLoop>.stride, options: .storageModeShared)!
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // Background (Aether)
        renderEncoder.setRenderPipelineState(backgroundPipelineState)
        renderEncoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(centerBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(hyleBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // Teslons
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(loopsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: loops.count)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }}
