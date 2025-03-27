//
//  Renderer.swift
//  Aexels
//
//  Created by Joe Charlier on 3/17/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    weak var view: MTKView?

    var size: CGSize = .zero

    let device: MTLDevice
    let library: MTLLibrary
    private let commandQueue: MTLCommandQueue

    init?(view: MTKView) {
        self.view = view
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library: MTLLibrary = device.makeDefaultLibrary()
        else { return nil }
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
        
        super.init()
        
        view.device = device
        view.delegate = self
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder) {}
    
    func createNormalRenderPipelineDescriptor(vertex: String, fragment: String) -> MTLRenderPipelineDescriptor! {
        guard let view else { return nil }
        let descriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertex)
        descriptor.fragmentFunction = library.makeFunction(name: fragment)
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        return descriptor
    }

// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = CGSize(width: size.width / view.contentScaleFactor, height: size.width / view.contentScaleFactor)
    }
    func draw(in view: MTKView) {
        guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor: MTLRenderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable: CAMetalDrawable = view.currentDrawable
        else { return }
        
        draw(renderEncoder: renderEncoder)
                
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
