//
//  ElectromagnetismRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import simd

struct NorthCamera {
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
    
    var universe: UnsafeMutablePointer<NCUniverse>?
    var systemCamera: UnsafeMutablePointer<NCCamera>?
    var aetherCamera: UnsafeMutablePointer<NCCamera>?
    
    private var position: SIMD2<Float>
    private var lastUpdateTime: CFTimeInterval
    
    private let systemCameraBuffer: MTLBuffer
    private let aetherCameraBuffer: MTLBuffer
    private var initialized: Bool = false
    
    private var backgroundTexture: MTLTexture
    private let backgroundPipelineState: MTLRenderPipelineState
//    private let linePipelineState: MTLRenderPipelineState
    
    weak var systemView: MTKView?
    weak var aetherView: MTKView?
    
    var t: Int = 0
    
    var speedOfLight: Int = 1 {
        didSet { NCUniverseSetC(universe, Double(speedOfLight)) }
    }
    var autoOn: Bool = true
    var wallsOn: Bool = true {
        didSet { NCCameraSetWalls(systemCamera, wallsOn ? 1 : 0) }
    }
    var hyleExchangeOn: Bool = true {
        didSet { NCUniverseSetHyleExchange(universe, hyleExchangeOn ? 1 : 0) }
    }
    var timeStepsPerVolley: Int = 60
    var pingsPerVolley: Int32 = 480
    var pingVectorsOn: Bool = false
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
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<NorthCamera>.size, options: .storageModeShared) else { return nil }
        
        self.systemCameraBuffer = cameraBuffer
        
        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<NorthCamera>.size, options: .storageModeShared) else { return nil }
        
        self.aetherCameraBuffer = cameraBuffer

        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "northLoopVertexShader")
        let fragmentFunction = library.makeFunction(name: "northLoopFragmentShader")
        
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
        
        // Ping Lines ==============================================================================

//        let lineVertexFunction = library.makeFunction(name: "northVertexShader")
//        let lineFragmentFunction = library.makeFunction(name: "northFragmentShader")
//
//        let linePipelineDescriptor = MTLRenderPipelineDescriptor()
//        linePipelineDescriptor.vertexFunction = lineVertexFunction
//        linePipelineDescriptor.fragmentFunction = lineFragmentFunction
//        linePipelineDescriptor.colorAttachments[0].pixelFormat = systemView.colorPixelFormat
//
//        // Configure vertex descriptor
//        let vertexDescriptor = MTLVertexDescriptor()
//        vertexDescriptor.attributes[0].format = .float2
//        vertexDescriptor.attributes[0].offset = 0
//        vertexDescriptor.attributes[0].bufferIndex = 0
//        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
//        linePipelineDescriptor.vertexDescriptor = vertexDescriptor
//
//        guard let linePipelineState = try? device.makeRenderPipelineState(descriptor: linePipelineDescriptor) else {
//            return nil
//        }
//        self.linePipelineState = linePipelineState
        
        // Ping Lines ==============================================================================

        super.init()
        
        systemView.delegate = self
        aetherView.delegate = self
    }
    
    var velocity: Double = 0 {
        didSet { NCUniverseSetSpeed(universe, velocity) }
    }
    var size: CGSize = .zero {
        didSet {
            guard let universe else { return }
            NCUniverseSetSize(universe, size.width, size.height)
        }
    }
    
    func loadExperiment() {
        guard let experiment: ElectromagnetismExperiment = experiment as? ElectromagnetismExperiment, let electromagnetism = experiment.electromagnetism, let systemView else { return }
        if let universe { NCUniverseRelease(universe) }
        
        let width: CGFloat = systemView.drawableSize.width / systemView.contentScaleFactor
        let height: CGFloat = systemView.drawableSize.height / systemView.contentScaleFactor
        
        universe = NCUniverseCreate(width, height)
        let velocity: Double = Double(electromagnetism.aetherVelocity)/100
        systemCamera = NCUniverseCreateCamera(universe, width/2, height/2, velocity, 0)
        NCCameraSetWalls(systemCamera, 1)
        aetherCamera = NCUniverseCreateCamera(universe, width/2, height/2, 0, 0)
        NCUniverseSetSpeed(universe, velocity)
        electromagnetism.regenerateTeslons(size: CGSize(width: width, height: height))
        electromagnetism.teslons.forEach { (teslon: Teslon) in
            NCUniverseCreateTeslon(universe, teslon.pX, teslon.pY, teslon.speed, teslon.orient, teslon.hyle, teslon.pings ? 1 : 0, teslon.contracts ? 1 : 0)
        }
    }
    
// Events ==========================================================================================
    func onPing() { NCUniversePing(universe, pingsPerVolley) }
    func onPong() { NCUniversePong(universe) }
    func onReset() { loadExperiment() }
    
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = CGSize(width: size.width / view.contentScaleFactor, height: size.height / view.contentScaleFactor)
        
        guard let experiment: ElectromagnetismExperiment = experiment as? ElectromagnetismExperiment, let electromagnetism = experiment.electromagnetism else { return }
//        NCUniverseSetSize(universe, size.width, size.height)
        electromagnetism.regenerateTeslons(size: size)
        loadExperiment()
    }
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor,
              let universe,
              let systemCamera,
              let aetherCamera
        else { return }
        
        let camera: UnsafeMutablePointer<NCCamera>
        let cameraBuffer: MTLBuffer
        if view === systemView {
            t += 1
            if autoOn && t % timeStepsPerVolley == 0 { NCUniversePing(universe, pingsPerVolley) }            
            NCUniverseTic(universe)
            NCUniverseCameraChasing(universe, aetherCamera, systemCamera);
            camera = systemCamera
            cameraBuffer = systemCameraBuffer
        } else /*if view === aetherView*/ {
            camera = aetherCamera
            cameraBuffer = aetherCameraBuffer
        }
        
        var northCamera: NorthCamera = NorthCamera(
            position: SIMD2<Float>(Float(camera.pointee.pos.x), Float(camera.pointee.pos.y)),
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)),
            hexBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height)),
            velocity: SIMD2<Float>(Float(camera.pointee.v.x), Float(camera.pointee.v.y)),
            hexWidth: Float(10.0 * Screen.s * 3),
            pingVectorsOn: pingVectorsOn,
            pongVectorsOn: pongVectorsOn,
            photonVectorsOn: photonVectorsOn
        )
        memcpy(cameraBuffer.contents(), &northCamera, MemoryLayout<NorthCamera>.size)
        
        var objects: [NorthLoop] = []
        var pings: [NorthLoop] = []

        for i: Int in 0..<Int(universe.pointee.teslonCount) {
            let teslon: UnsafeMutablePointer<NCTeslon> = universe.pointee.teslons[i]!
            let object: NorthLoop = NorthLoop(
                type: 0,
                position: SIMD2<Float>(Float(teslon.pointee.pos.x), Float(teslon.pointee.pos.y)),
                velocity: SIMD2<Float>(Float(teslon.pointee.v.x), Float(teslon.pointee.v.y)),
                cupola: SIMD2<Float>(0, 0),
                hyle: Float(teslon.pointee.hyle)
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
        
        // =================================================================================================

//                var lineVertices: [SIMD2<Float>] = []
//
//                for i in 0..<Int(universe.pointee.pingCount) {
//                    let ping = universe.pointee.pings[i]!
//                    
//                    if let sourceTeslon = ping.pointee.source {
//                        // Ping position (origin)
//                        lineVertices.append(SIMD2<Float>(
//                            Float(ping.pointee.pos.x),
//                            Float(ping.pointee.pos.y)
//                        ))
//                        
//                        // Current teslon position
//                        lineVertices.append(SIMD2<Float>(
//                            Float(sourceTeslon.pointee.pos.x),
//                            Float(sourceTeslon.pointee.pos.y)
//                        ))
//                    }
//                }
//
//                if !lineVertices.isEmpty {
//                    let lineBuffer = device.makeBuffer(
//                        bytes: lineVertices,
//                        length: lineVertices.count * MemoryLayout<SIMD2<Float>>.stride,
//                        options: .storageModeShared
//                    )!
//                    
//                    renderEncoder.setRenderPipelineState(linePipelineState)
//                    renderEncoder.setVertexBuffer(lineBuffer, offset: 0, index: 0)
//                    renderEncoder.setVertexBuffer(cameraBuffer, offset: 0, index: 1)
//                    renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: lineVertices.count)
//                }
                
        // =================================================================================================


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
