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

class GravityRenderer: Renderer {
    var universe: UnsafeMutablePointer<CCUniverse>?
    
    private var universeBuffer: MTLBuffer!
    
    override init?(view: MTKView) {
        super.init(view: view)
        
        guard let universeBuffer = device.makeBuffer(length: MemoryLayout<MGUniverse>.size, options: .storageModeShared) else { return nil }
        self.universeBuffer = universeBuffer
    }
    
    lazy var aexelPipelineState: MTLRenderPipelineState! = {
        guard let view else { return nil }
        
        let descriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "mgAexelVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "mgAexelFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        guard let state: MTLRenderPipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        
        return state
    }()
    
    lazy var bondsPipelineState: MTLRenderPipelineState! = {
        guard let view else { return nil }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "mgBondsVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "mgBondsFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        descriptor.vertexDescriptor = vertexDescriptor

        guard let state: MTLRenderPipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        
        return state
    }()
    
    func loadExperiment() {
        universe = CCUniverseCreate(size.width, size.height)
        let a = CCUniverseCreateAexelAt(universe, 100, 100)
        let b = CCUniverseCreateAexelAt(universe, 200, 150)
        let c = CCUniverseCreateAexelAt(universe, 200, 300)
        let d = CCUniverseCreateAexelAt(universe, 400, 300)
        CCUniverseCreateBondBetween(universe, a, b)
        CCUniverseCreateBondBetween(universe, c, d)
    }
    
// MTKViewDelegate =================================================================================
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        super.mtkView(view, drawableSizeWillChange: size)
        loadExperiment()
    }
    
// Renderer ========================================================================================
    override func draw(renderEncoder: any MTLRenderCommandEncoder) {
        guard let universe else { return }
        
//        var mgUniverse: MGUniverse = MGUniverse(bounds: SIMD2<Float>(Float(size.width), Float(size.height)))
//        memcpy(universeBuffer.contents(), &mgUniverse, MemoryLayout<MGUniverse>.size)

        // Bonds ================
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt16] = []
        
        for i: Int32 in 0..<universe.pointee.aexelCount {
            let aexel: UnsafeMutablePointer<CCAexel> = universe.pointee.aexels[Int(i)]!
            let aexelCenter: SIMD2<Float> = SIMD2<Float>(Float(size.width/2) + Float(aexel.pointee.pos.x), Float(size.width/2) + Float(aexel.pointee.pos.y))
            vertices.append(SIMD2<Float>((aexelCenter.x / Float(size.width) * 2) - 1, -((aexelCenter.y / Float(size.height) * 2) - 1)))
        }

        for i: Int32 in 0..<universe.pointee.bondCount {
            let bond: UnsafeMutablePointer<CCBond> = universe.pointee.bonds[Int(i)]!
            indices.append(UInt16(bond.pointee.a.pointee.index))
            indices.append(UInt16(bond.pointee.b.pointee.index))
        }
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeShared) else { fatalError() }
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: .storageModeShared) else { fatalError() }
        
        renderEncoder.setRenderPipelineState(bondsPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .line, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)

        // Aexels ===============
        var aexels: [MGAexelIn] = []
        for i in 0..<Int(universe.pointee.aexelCount) {
            let aexel = universe.pointee.aexels[i]!
            let aexelCenter: SIMD2<Float> = SIMD2<Float>(Float(size.width/2) + Float(aexel.pointee.pos.x), Float(size.width/2) + Float(aexel.pointee.pos.y))
            let position = SIMD2<Float>((aexelCenter.x / Float(size.width) * 2) - 1, -((aexelCenter.y / Float(size.height) * 2) - 1))
            aexels.append(MGAexelIn(position: position))
        }
        
        guard let aexelBuffer: MTLBuffer = device.makeBuffer(bytes: aexels, length: aexels.count * MemoryLayout<MGAexelIn>.stride, options: .storageModeShared) else { return }
        
        renderEncoder.setRenderPipelineState(aexelPipelineState)
        renderEncoder.setVertexBuffer(aexelBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: aexels.count)
    }
}
