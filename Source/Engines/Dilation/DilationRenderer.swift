//
//  DilationRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import simd

struct ThracianCamera {
    var position: SIMD2<Float>
    var bounds: SIMD2<Float>
    var hexBounds: SIMD2<Float>
    var velocity: SIMD2<Float>
    var hexWidth: Float
    var pingVectorsOn: Bool
    var pongVectorsOn: Bool
    var photonVectorsOn: Bool
    var padding: Int8 = 0
};

struct ThracianLoop {
    var type: Int
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
};

class DilationRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    
    var universe: UnsafeMutablePointer<TCUniverse>?
    var source: UnsafeMutablePointer<TCTeslon>?
    var vertical: UnsafeMutablePointer<TCTeslon>?
    var horizontal: UnsafeMutablePointer<TCTeslon>?
    var systemCamera: UnsafeMutablePointer<TCCamera>?
    var aetherCamera: UnsafeMutablePointer<TCCamera>?
    
    private var position: SIMD2<Float>
    private var lastUpdateTime: CFTimeInterval
    
    private let systemCameraBuffer: MTLBuffer
    private let aetherCameraBuffer: MTLBuffer
    private var initialized: Bool = false
    
    private var backgroundTexture: MTLTexture
    private let backgroundPipelineState: MTLRenderPipelineState
    
    weak var systemView: MTKView?
    weak var aetherView: MTKView?
    
    var t: Int = 0
    
    var speedOfLight: Int = 1 {
        didSet { TCUniverseSetC(universe, Double(speedOfLight)) }
    }
    var velocity: Double = 0.2 {
        didSet {
            TCUniverseSetSpeed(universe, velocity)
            horizontal?.pointee.p = TCV2(x: source!.pointee.p.x + size.width/5/(contractOn ? TCGamma(velocity) : 1), y: source!.pointee.p.y)
        }
    }
    var size: CGSize = .zero
//    {
//        didSet {
//            guard let universe else { return }
//            TCUniverseSetSize(universe, size.width, size.height)
//        }
//    }
    var autoOn: Bool = true
    var tailsOn: Bool = true {
        didSet {
            pingVectorsOn = tailsOn
            pongVectorsOn = tailsOn
        }
    }
    var horizontalOn: Bool = false
    var contractOn: Bool = true

    var timeStepsPerVolley: Int = 120
    var pingsPerVolley: Int32 = 99
    var pingVectorsOn: Bool = true
    var pongVectorsOn: Bool = true
    var photonVectorsOn: Bool = true
    
    var experiment: Experiment? {
        didSet { loadExperiment() }
    }

    init?(systemView: MTKView, aetherView: MTKView) {
        self.systemView = systemView
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        systemView.device = device
        aetherView.device = device
        
        position = SIMD2<Float>(0, 0)
        lastUpdateTime = CACurrentMediaTime()
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<ThracianCamera>.size, options: .storageModeShared) else { return nil }
        
        self.systemCameraBuffer = cameraBuffer
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<ThracianCamera>.size, options: .storageModeShared) else { return nil }
        
        self.aetherCameraBuffer = cameraBuffer

        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "thracianLoopVertexShader")
        let fragmentFunction = library.makeFunction(name: "thracianLoopFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = systemView.colorPixelFormat
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
                
        let backgroundVertexFunction = library.makeFunction(name: "northAetherVertexShader")
        let backgroundFragmentFunction = library.makeFunction(name: "northAetherFragmentShader")
        
        let backgroundPipelineDescriptor = MTLRenderPipelineDescriptor()
        backgroundPipelineDescriptor.vertexFunction = backgroundVertexFunction
        backgroundPipelineDescriptor.fragmentFunction = backgroundFragmentFunction
        backgroundPipelineDescriptor.colorAttachments[0].pixelFormat = systemView.colorPixelFormat
        
        guard let backgroundPipelineState = try? device.makeRenderPipelineState(descriptor: backgroundPipelineDescriptor) else { return nil }
        self.backgroundPipelineState = backgroundPipelineState
        
        let image: UIImage = Engine.renderHex(size: CGSize(width: Screen.height, height: Screen.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let backgroundTexture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB : false]) else { return nil }
        self.backgroundTexture = backgroundTexture

        super.init()
        
        systemView.delegate = self
        aetherView.delegate = self
    }
        
    func loadExperiment() {
        universe = TCUniverseCreate(size.width, size.height, 1)
        source = TCUniverseCreateTeslon(universe, size.width/2, size.height/2, velocity, .pi/2)
        vertical = TCUniverseCreateTeslon(universe, size.width/2, size.height/2 - size.width/5, velocity, .pi/2)
        if horizontalOn { horizontal = TCUniverseCreateTeslon(universe, size.width/2 + size.width/5/TCGamma(velocity), size.height/2, velocity, .pi/2) }
        systemCamera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
        aetherCamera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
    }
    
// Events ==========================================================================================
    func onPing() { TCUniversePulse(universe, source, pingsPerVolley) }
    func onReset() { loadExperiment() }
    
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = CGSize(width: size.width / view.contentScaleFactor, height: size.height / view.contentScaleFactor)
        loadExperiment()
    }
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor,
              let universe,
              let systemCamera,
              let aetherCamera
        else { return }
        
        let camera: UnsafeMutablePointer<TCCamera>
        let cameraBuffer: MTLBuffer
        if view === systemView {
            t += 1
            if autoOn && t % timeStepsPerVolley == 0 { TCUniversePulse(universe, source, pingsPerVolley) }
            TCUniverseTic(universe)
            TCUniverseCameraChasing(universe, aetherCamera, systemCamera);
            camera = systemCamera
            cameraBuffer = systemCameraBuffer
        } else /*if view === aetherView*/ {
            camera = aetherCamera
            cameraBuffer = aetherCameraBuffer
        }
        
        var thracianCamera: ThracianCamera = ThracianCamera(
            position: SIMD2<Float>(Float(camera.pointee.p.x), Float(camera.pointee.p.y)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)),
            hexBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height)),
            velocity: SIMD2<Float>(Float(camera.pointee.v.s), Float(camera.pointee.v.q)),
            hexWidth: Float(10.0 * Screen.s * 3),
            pingVectorsOn: pingVectorsOn,
            pongVectorsOn: pongVectorsOn,
            photonVectorsOn: photonVectorsOn
        )
        memcpy(cameraBuffer.contents(), &thracianCamera, MemoryLayout<ThracianCamera>.size)
        
        var objects: [ThracianLoop] = []
        var pings: [ThracianLoop] = []

        for i: Int in 0..<Int(universe.pointee.teslonCount) {
            let teslon: UnsafeMutablePointer<TCTeslon> = universe.pointee.teslons[i]!
            let object: ThracianLoop = ThracianLoop(
                type: 0,
                position: SIMD2<Float>(Float(teslon.pointee.p.x), Float(teslon.pointee.p.y)),
                velocity: SIMD2<Float>(Float(teslon.pointee.v.s), Float(teslon.pointee.v.q))
            )
            objects.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.pingCount) {
            let ping: UnsafeMutablePointer<TCPing> = universe.pointee.pings[i]!
            let object: ThracianLoop = ThracianLoop(
                type: 1,
                position: SIMD2<Float>(Float(ping.pointee.p.x), Float(ping.pointee.p.y)),
                velocity: SIMD2<Float>(Float(ping.pointee.o.x-ping.pointee.p.x), Float(ping.pointee.o.y-ping.pointee.p.y))
            )
            pings.append(object)
        }
        for i: Int in 0..<Int(universe.pointee.photonCount) {
            let pong: UnsafeMutablePointer<TCPong> = universe.pointee.photons[i]!
            let object: ThracianLoop = ThracianLoop(
                type: 2,
                position: SIMD2<Float>(Float(pong.pointee.p.x), Float(pong.pointee.p.y)),
                velocity: SIMD2<Float>(Float(pong.pointee.o.x - pong.pointee.p.x), Float(pong.pointee.o.y-pong.pointee.p.y))
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
