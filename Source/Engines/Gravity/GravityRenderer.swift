//
//  GravityRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 2/26/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation
import MetalKit
import OoviumEngine
import OoviumKit

struct MyrtoanUniverse {
    var bounds: SIMD2<Float>
    var cartBounds: SIMD2<Float>
};

struct MyrtoanCirclePacket {
    var center: SIMD2<Float>
    var radius: Float
    var color: SIMD4<Float>
}

//struct MyrtoanRingPacket {
//    var center: SIMD2<Float>
//    var innerRadius: Float
//    var outerRadius: Float
//    var fillColor: SIMD4<Float>
//}

struct MyrtoanRingIn {
    var center: SIMD2<Float>
    var iR: Float
    var oR: Float
    var color: SIMD4<Float>
    var focus: UInt8
}

struct MyratoanVertexIn {
    let position: SIMD2<Float>
}


class GravityRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var backgroundTexture: MTLTexture
    private let backgroundPipelineState: MTLRenderPipelineState
    private let universeBuffer: MTLBuffer
    
    private let circlePipelineState: MTLRenderPipelineState
    private let planetCircleBuffer: MTLBuffer
    private let moonCircleBuffer: MTLBuffer
    
    private let ringPipelineState: MTLRenderPipelineState
    
    private let pipelineState: MTLRenderPipelineState
    
    private let hexagonParamsBuffer: MTLBuffer
    
    var size: CGSize = .zero
    var universe: UnsafeMutablePointer<MCUniverse>?

    weak var view: MTKView?
    
    init?(view: MTKView) {
        self.view = view
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        view.device = device
        let library = device.makeDefaultLibrary()!
        
        guard let universeBuffer = device.makeBuffer(length: MemoryLayout<MyrtoanUniverse>.size, options: .storageModeShared) else { return nil }
        self.universeBuffer = universeBuffer
        
        let backgroundVertexFunction = library.makeFunction(name: "myrtoanCartesianVertexShader")
        let backgroundFragmentFunction = library.makeFunction(name: "myrtoanCartesianFragmentShader")
        
        let backgroundPipelineDescriptor = MTLRenderPipelineDescriptor()
        backgroundPipelineDescriptor.vertexFunction = backgroundVertexFunction
        backgroundPipelineDescriptor.fragmentFunction = backgroundFragmentFunction
        backgroundPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        guard let backgroundPipelineState = try? device.makeRenderPipelineState(descriptor: backgroundPipelineDescriptor) else { return nil }
        self.backgroundPipelineState = backgroundPipelineState
        
        let image: UIImage = Engine.renderCartesian(size: CGSize(width: Screen.height, height: Screen.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let backgroundTexture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB : false]) else { return nil }
        self.backgroundTexture = backgroundTexture
        
        let circleVertexFunction = library.makeFunction(name: "myrtoanCircleVectorShader")
        let circleFragmentFunction = library.makeFunction(name: "myrtoanCircleFragmentShader")
            
        let circlePipelineDescriptor = MTLRenderPipelineDescriptor()
        circlePipelineDescriptor.vertexFunction = circleVertexFunction
        circlePipelineDescriptor.fragmentFunction = circleFragmentFunction
        circlePipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
        circlePipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        circlePipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        circlePipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        circlePipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        circlePipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            
        guard let circlePipelineState = try? device.makeRenderPipelineState(descriptor: circlePipelineDescriptor) else { return nil }
        self.circlePipelineState = circlePipelineState

        guard let planetCircleBuffer = device.makeBuffer(length: MemoryLayout<MyrtoanCirclePacket>.size, options: .storageModeShared) else { return nil }
        self.planetCircleBuffer = planetCircleBuffer

        guard let moonCircleBuffer = device.makeBuffer(length: MemoryLayout<MyrtoanCirclePacket>.size, options: .storageModeShared) else { return nil }
        self.moonCircleBuffer = moonCircleBuffer
        
        let ringVertexFunction: MTLFunction = library.makeFunction(name: "myrtoanRingVertexShader")!
        let ringFragmentFunction: MTLFunction = library.makeFunction(name: "myrtoanRingFragmentShader")!

        let ringPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        ringPipelineDescriptor.vertexFunction = ringVertexFunction
        ringPipelineDescriptor.fragmentFunction = ringFragmentFunction
        ringPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        ringPipelineDescriptor.colorAttachments[0].isBlendingEnabled = false
        ringPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        ringPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        ringPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        ringPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        ringPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        ringPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        guard let ringPipelineState = try? device.makeRenderPipelineState(descriptor: ringPipelineDescriptor) else { return nil }
        self.ringPipelineState = ringPipelineState

        guard let hexagonParamsBuffer = device.makeBuffer(length: MemoryLayout<MyrtoanRingIn>.size, options: .storageModeShared) else { fatalError("Params buffer failed") }
        self.hexagonParamsBuffer = hexagonParamsBuffer
        
        
        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else { fatalError("Shaders not found") }

        // Pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm  // Match your view’s format

        // Vertex layout
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<MyratoanVertexIn>.stride
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        // Create pipeline state
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else { fatalError("Pipeline failed") }
        self.pipelineState = pipelineState
        
        
        super.init()
        
        view.delegate = self
    }
    
    func loadExperiment() {
        if universe == nil { MCUniverseRelease(universe) }
        universe = MCUniverseCreate(size.width, size.height)
        let dC: Double = 0.4
        MCUniverseCreateRing(universe, 450, 350, 72, 1*dC)
        MCUniverseCreateRing(universe, 350, 270, 54, 2*dC)
        MCUniverseCreateRing(universe, 270, 210, 42, 3*dC)
        MCUniverseCreateRing(universe, 210, 170, 30, 4*dC)
        MCUniverseCreateRing(universe, 170, 140, 24, 5*dC)
        MCUniverseCreateRing(universe, 140, 120, 20, 6*dC)
        MCUniverseCreateRing(universe, 120, 100, 18, 7*dC)
        MCUniverseCreateRing(universe, 100,  80, 15, 8*dC)
        MCUniverseCreateMoon(universe, -160, -120, 1, -1, 20)
    }

// Events ==========================================================================================
    func onReset() { loadExperiment() }
        
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = CGSize(width: size.width / view.contentScaleFactor, height: size.width / view.contentScaleFactor)
        loadExperiment()
    }
    func draw(in view: MTKView) {
        guard let drawable: CAMetalDrawable = view.currentDrawable,
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor,
              let universe
        else { return }
        
        MCUniverseTic(universe)
        
        // Cartesian ===============================================================================
        var myrtoanUniverse: MyrtoanUniverse = MyrtoanUniverse(
            bounds: SIMD2<Float>(Float(universe.pointee.width), Float(universe.pointee.height)),
            cartBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height))
        )
        memcpy(universeBuffer.contents(), &myrtoanUniverse, MemoryLayout<MyrtoanUniverse>.size)
                
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(backgroundPipelineState)
        renderEncoder.setVertexBuffer(universeBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // Planet ==================================================================================
        var planets: [MyrtoanCirclePacket] = []
        if let planet = universe.pointee.planet {
            let centerPoint = SIMD2<Float>(Float(size.width/2), Float(size.width/2))
            let normalizedCenter = SIMD2<Float>(
                (centerPoint.x / Float(size.width) * 2) - 1,
                -((centerPoint.y / Float(size.width) * 2) - 1)
            )
            
            let planetCircle = MyrtoanCirclePacket(
                center: normalizedCenter,
                radius: Float(planet.pointee.radius) / Float(size.width) * 2,
                color: OOColor.cobolt.simd4
            )
            planets.append(planetCircle)
        }
        
        let planetsBuffer = device.makeBuffer(bytes: planets, length: planets.count * MemoryLayout<MyrtoanCirclePacket>.stride, options: .storageModeShared)!
        
        renderEncoder.setRenderPipelineState(circlePipelineState)
        renderEncoder.setVertexBuffer(planetsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(planetsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: planets.count)

        // Rings ===================================================================================
        var rings: [MyrtoanRingIn] = []
        for i in 0..<universe.pointee.ringCount {
            let ring: UnsafeMutablePointer<MCRing> = universe.pointee.rings[Int(i)]!
            
            let centerPoint: SIMD2<Float> = SIMD2<Float>(Float(size.width/2), Float(size.width/2))
            let normalizedCenter: SIMD2<Float> = SIMD2<Float>(
                (centerPoint.x / Float(size.width) * 2) - 1,
                -((centerPoint.y / Float(size.width) * 2) - 1)
            )
            
            let iR: Float = Float(ring.pointee.iR) / Float(size.width) * 2
            let oR: Float = Float(ring.pointee.oR) / Float(size.width) * 2
            
            rings.append(MyrtoanRingIn(
                center: normalizedCenter,
                iR: iR,
                oR: oR,
                color: i % 2 == 0 ? UIColor.blue.tone(0.9).simd4 : UIColor.blue.tone(0.9).tint(0.1).simd4,
                focus: ring.pointee.focus
            ))
        }
        
        let ringsBuffer = device.makeBuffer(bytes: rings, length: rings.count * MemoryLayout<MyrtoanRingIn>.stride, options: .storageModeShared)!
        
        renderEncoder.setRenderPipelineState(ringPipelineState)
        renderEncoder.setVertexBuffer(ringsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(ringsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: rings.count)

        // Hexes ===================================================================================
        rings = []
        for i in 0..<universe.pointee.ringCount {
            let ring: UnsafeMutablePointer<MCRing> = universe.pointee.rings[Int(i)]!
            rings.append(MyrtoanRingIn(
                center: SIMD2<Float>(Float(size.width*view.contentScaleFactor/2), Float(size.width*view.contentScaleFactor/2)),
                iR: Float(ring.pointee.iR+2)*Float(view.contentScaleFactor),
                oR: Float(ring.pointee.oR-2)*Float(view.contentScaleFactor),
                color: UIColor.blue.tone(0.9).simd4,
                focus: ring.pointee.focus
            ))
        }

        let ringsBuffer2 = device.makeBuffer(bytes: rings, length: rings.count * MemoryLayout<MyrtoanRingIn>.stride, options: .storageModeShared)!

        var vI: UInt16
        var rI: UInt16
        var qI: UInt16
        var qW: UInt16
        
        for i: Int32 in 0..<universe.pointee.ringCount {
            
            vI = 0
            rI = 0
            qI = 0
            qW = 0
            
            let ring: UnsafeMutablePointer<MCRing> = universe.pointee.rings[Int(i)]!
            
            var r: Float = Float(ring.pointee.iR + ring.pointee.o)
            
            // Create a buffer for the ring index
            var ringIndex = UInt32(i)
            let ringIndexBuffer = device.makeBuffer(bytes: &ringIndex, length: MemoryLayout<UInt32>.size, options: .storageModeShared)!

            renderEncoder.setVertexBuffer(ringsBuffer2, offset: 0, index: 1)
            renderEncoder.setVertexBuffer(ringIndexBuffer, offset: 0, index: 2)
            renderEncoder.setFragmentBuffer(ringsBuffer2, offset: 0, index: 1)
            renderEncoder.setFragmentBuffer(ringIndexBuffer, offset: 0, index: 2)
            
            var vertices: [MyratoanVertexIn] = []
            var indices: [UInt16] = []
            
            while r < Float(ring.pointee.oR + ring.pointee.dR) {
                    
                var q: Float = rI % 2 == 0 ? 0 : Float(ring.pointee.dQ / 2)
                
                while q < 2 * .pi - Float(ring.pointee.dQ / 3) {
                    let x = Float(size.width/2) + r * cos(q)
                    let y = Float(size.width/2) + r * sin(q)
                    
                    let normalizedPos = SIMD2<Float>(
                        (x / Float(size.width) * 2) - 1,
                        -((y / Float(size.width) * 2) - 1)
                    )
                    vertices.append(MyratoanVertexIn(position: normalizedPos))

                    if rI > 0 && qI < qW {
                        if vI % 3 == 0 {
                            if rI % 2 == 1 {
                                let a = vI
                                let b = vI - qW
                                indices.append(a)
                                indices.append(a+1)
                                indices.append(a)
                                indices.append(b)
                                indices.append(a+1)
                                indices.append(b+2)
                            } else {
                                let a = vI
                                let b = vI - qW
                                indices.append(a)
                                indices.append(b)
                                indices.append(b+1)
                                indices.append(a+2)
                                indices.append(a+2)
                                if (a+3) % qW == 0 { indices.append(a+3-qW) }
                                else { indices.append(a+3) }
                            }
                        }
                    }
                                        
                    vI += 1

                    q += Float(ring.pointee.dQ)
                    qI += 1
                }
                
                r += Float(ring.pointee.dR)
                rI += 1
                if rI == 1 { qW = qI }
                qI = 0
            }
            
            guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<MyratoanVertexIn>.stride, options: .storageModeShared) else { fatalError("Vertex buffer failed") }
            guard let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: .storageModeShared) else { fatalError("Index buffer failed") }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .line, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        
        // Moons ===================================================================================
        var moonCircles: [MyrtoanCirclePacket] = []
        for i in 0..<universe.pointee.moonCount {
            let moon: UnsafeMutablePointer<MCMoon> = universe.pointee.moons[Int(i)]!
            let centerPoint = SIMD2<Float>(
                Float(size.width/2) + Float(moon.pointee.pos.x),
                Float(size.width/2) + Float(moon.pointee.pos.y)
            )
            let normalizedCenter = SIMD2<Float>(
                (centerPoint.x / Float(size.width) * 2) - 1,
                -((centerPoint.y / Float(size.height) * 2) - 1)
            )
            
            let moonCircle: MyrtoanCirclePacket = MyrtoanCirclePacket(
                center: normalizedCenter,
                radius: Float(moon.pointee.radius) / Float(size.width) * 2,
                color: OOColor.marine.simd4
            )
            moonCircles.append(moonCircle)
        }
        
        let moonsBuffer = device.makeBuffer(bytes: moonCircles, length: moonCircles.count * MemoryLayout<MyrtoanCirclePacket>.stride, options: .storageModeShared)!
        
        renderEncoder.setRenderPipelineState(circlePipelineState)
        renderEncoder.setVertexBuffer(moonsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(moonsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: moonCircles.count)
        
        // Final Commit ============================================================================
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
