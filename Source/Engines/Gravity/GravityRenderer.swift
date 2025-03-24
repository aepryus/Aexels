//
//  GravityRenderer.swift
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import MetalKit
import OoviumEngine
import OoviumKit
import simd

struct MGUniverse {
    var bounds: SIMD2<Float>
}

struct MGCirclePacket {
    var center: SIMD2<Float>
    var radius: Float
    var color: SIMD4<Float>
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
    
    lazy var circlePipelineState: MTLRenderPipelineState! =  {
        guard let view else { return nil }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "mgCircleVectorShader")
        descriptor.fragmentFunction = library.makeFunction(name: "mgCircleFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        
        return state
    }()
    
    func loadExperiment() {
        guard size.width > 300 else { return }
        
        let universe: UnsafeMutablePointer<CCUniverse> = CCUniverseCreate(size.width, size.height)
        CCUniverseDemarcate(universe)
        
        let ds: Double = universe.pointee.ds
        
        let dx: Double = universe.pointee.radiusBond
        let dy: Double = dx * sqrt(3)/2

        let x0: Double = -Double(universe.pointee.sectorCountX) * ds/2
        let y0: Double = -Double(universe.pointee.sectorCountY) * ds/2

        var x: Double = x0
        var y: Double = y0
        
        let maxX: Double = Double(universe.pointee.sectorCountX) * ds/2
        let maxY: Double = Double(universe.pointee.sectorCountY) * ds/2
        
        var p: Bool = false
        
        while y < maxY {
            while x < maxX {
                CCUniverseCreateAexelAt(universe, x, y)
                x += dx
            }
            x = x0 + (p ? 0 : dx/2)
            y += dy
            p = !p
        }
        
        CCUniverseBind(universe)
        
        self.universe = universe
    }
    
// MTKViewDelegate =================================================================================
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        super.mtkView(view, drawableSizeWillChange: size)
        loadExperiment()
    }
    
// Renderer ========================================================================================
    override func draw(renderEncoder: any MTLRenderCommandEncoder) {
        guard let universe else { return }
        
        CCUniverseTic(universe)
        
//        var mgUniverse: MGUniverse = MGUniverse(bounds: SIMD2<Float>(Float(size.width), Float(size.height)))
//        memcpy(universeBuffer.contents(), &mgUniverse, MemoryLayout<MGUniverse>.size)

        // Bonds ================
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt16] = []
        
        for i: Int32 in 0..<universe.pointee.aexelCount {
            let aexel: UnsafeMutablePointer<CCAexel> = universe.pointee.aexels[Int(i)]!
            let aexelCenter: SIMD2<Float> = SIMD2<Float>(Float(size.width/2) + Float(aexel.pointee.position.x), Float(size.width/2) + Float(aexel.pointee.position.y))
            vertices.append(SIMD2<Float>((aexelCenter.x / Float(size.width) * 2) - 1, -((aexelCenter.y / Float(size.height) * 2) - 1)))
        }

        for i: Int32 in 0..<universe.pointee.aexelCount {
            let aexel: UnsafeMutablePointer<CCAexel> = universe.pointee.aexels[Int(i)]!
            for j: Int32 in 0..<aexel.pointee.adminCount {
                let bond: UnsafeMutablePointer<CCBond> = aexel.pointee.admin[Int(j)]!
                indices.append(UInt16(bond.pointee.a.pointee.index))
                indices.append(UInt16(bond.pointee.b.pointee.index))
            }
        }
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeShared) else { fatalError() }
        
        let indexBuffer: MTLBuffer? = indices.count > 0 ? device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: .storageModeShared) : nil
        
        renderEncoder.setRenderPipelineState(bondsPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        if let indexBuffer {
            renderEncoder.drawIndexedPrimitives(type: .line, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }

        // Aexels ===============
        var aexels: [MGAexelIn] = []
        for i in 0..<Int(universe.pointee.aexelCount) {
            let aexel = universe.pointee.aexels[i]!
            let aexelCenter: SIMD2<Float> = SIMD2<Float>(Float(size.width/2) + Float(aexel.pointee.position.x), Float(size.width/2) + Float(aexel.pointee.position.y))
            let position = SIMD2<Float>((aexelCenter.x / Float(size.width) * 2) - 1, -((aexelCenter.y / Float(size.height) * 2) - 1))
            aexels.append(MGAexelIn(position: position))
        }
        
        guard let aexelBuffer: MTLBuffer = device.makeBuffer(bytes: aexels, length: aexels.count * MemoryLayout<MGAexelIn>.stride, options: .storageModeShared) else { return }
        
        renderEncoder.setRenderPipelineState(aexelPipelineState)
        renderEncoder.setVertexBuffer(aexelBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: aexels.count)
        
        // Planet ===============
        var planets: [MGCirclePacket] = []
        if let planet = universe.pointee.planet {
            let centerPoint = SIMD2<Float>(Float(size.width/2), Float(size.width/2))
            let normalizedCenter = SIMD2<Float>(
                (centerPoint.x / Float(size.width) * 2) - 1,
                -((centerPoint.y / Float(size.width) * 2) - 1)
            )
            
            let planetCircle = MGCirclePacket(
                center: normalizedCenter,
                radius: Float(planet.pointee.radius) / Float(size.width) * 2,
                color: OOColor.cobolt.uiColor.alpha(0.5).simd4
            )
            planets.append(planetCircle)
        }
        
        let planetsBuffer = device.makeBuffer(bytes: planets, length: planets.count * MemoryLayout<MGCirclePacket>.stride, options: .storageModeShared)!
        
        renderEncoder.setRenderPipelineState(circlePipelineState)
        renderEncoder.setVertexBuffer(planetsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(planetsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: planets.count)
    }
}
