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
