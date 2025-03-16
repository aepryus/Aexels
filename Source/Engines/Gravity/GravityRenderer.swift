//
//  GravityRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import MetalKit
import simd

struct MGUniverse {
    var bounds: SIMD2<Float>
}

struct MGAexelIn {
    var position: SIMD2<Float>
}

class GravityRenderer: NSObject, MTKViewDelegate {
    var size: CGSize = .zero
    var universe: UnsafeMutablePointer<CCUniverse>?
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let universeBuffer: MTLBuffer
    private let aexelPipelineState: MTLRenderPipelineState
    
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
        
        guard let library = device.makeDefaultLibrary() else { return nil }
        
        // Create universe buffer
        guard let universeBuffer = device.makeBuffer(length: MemoryLayout<MGUniverse>.size, options: .storageModeShared) else { return nil }
        self.universeBuffer = universeBuffer
        
        // Create aexel rendering pipeline
        let aexelVertexFunction = library.makeFunction(name: "mgAexelVertexShader")
        let aexelFragmentFunction = library.makeFunction(name: "mgAexelFragmentShader")
        
        let aexelPipelineDescriptor = MTLRenderPipelineDescriptor()
        aexelPipelineDescriptor.vertexFunction = aexelVertexFunction
        aexelPipelineDescriptor.fragmentFunction = aexelFragmentFunction
        aexelPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        // Enable alpha blending
        aexelPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        aexelPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        aexelPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        aexelPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        aexelPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        guard let aexelPipelineState = try? device.makeRenderPipelineState(descriptor: aexelPipelineDescriptor) else { return nil }
        self.aexelPipelineState = aexelPipelineState
        
        super.init()
        
        view.delegate = self
    }

    func loadExperiment() {
        universe = CCUniverseCreate(size.width, size.height)
        CCUniverseCreateAexelAt(universe, 100, 100);
        CCUniverseCreateAexelAt(universe, 200, 150);
        CCUniverseCreateAexelAt(universe, 200, 300);
        CCUniverseCreateAexelAt(universe, 400, 300);
    }
    
// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = CGSize(width: size.width / view.contentScaleFactor, height: size.width / view.contentScaleFactor)
        loadExperiment()
    }
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
                     let renderPassDescriptor = view.currentRenderPassDescriptor,
                     let universe = universe else { return }
               
           // Update universe physics
           // CCUniverseTic(universe)
           
           // Update Metal buffers
           var mgUniverse = MGUniverse(
               bounds: SIMD2<Float>(Float(size.width), Float(size.height))
           )
           memcpy(universeBuffer.contents(), &mgUniverse, MemoryLayout<MGUniverse>.size)
           
           // Create aexel buffer
           var aexels: [MGAexelIn] = []
           for i in 0..<Int(universe.pointee.aexelCount) {
               let aexel = universe.pointee.aexels[i]!
               
               let centerPoint = SIMD2<Float>(
                   Float(size.width/2) + Float(aexel.pointee.pos.x),
                   Float(size.width/2) + Float(aexel.pointee.pos.y)
               )
               let normalizedCenter = SIMD2<Float>(
                   (centerPoint.x / Float(size.width) * 2) - 1,
                   -((centerPoint.y / Float(size.height) * 2) - 1)
               )

               let position = SIMD2<Float>(
                   Float(normalizedCenter.x),
                   Float(normalizedCenter.y)
               )
               aexels.append(MGAexelIn(position: position))
           }
           
           guard let aexelBuffer = device.makeBuffer(bytes: aexels,
                                                    length: aexels.count * MemoryLayout<MGAexelIn>.stride,
                                                    options: .storageModeShared) else { return }
           
           // Command encoding
           guard let commandBuffer = commandQueue.makeCommandBuffer(),
                 let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
               return
           }
           
           // Clear background
           renderEncoder.setRenderPipelineState(aexelPipelineState)
           
           // Draw aexels
           renderEncoder.setVertexBuffer(aexelBuffer, offset: 0, index: 0)
           renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: aexels.count)
           
           renderEncoder.endEncoding()
           
           commandBuffer.present(drawable)
           commandBuffer.commit()
    }
}
    
