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
        let descriptor: MTLRenderPipelineDescriptor = createNormalRenderPipelineDescriptor(vertex: "mgAexelVertexShader", fragment: "mgAexelFragmentShader")
        guard let state: MTLRenderPipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        return state
    }()
    
    lazy var bondsPipelineState: MTLRenderPipelineState! = {
        guard let view else { return nil }
        
        let descriptor: MTLRenderPipelineDescriptor = createNormalRenderPipelineDescriptor(vertex: "mgBondsVertexShader", fragment: "mgBondsFragmentShader")

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
        let descriptor: MTLRenderPipelineDescriptor = createNormalRenderPipelineDescriptor(vertex: "mgCircleVectorShader", fragment: "mgCircleFragmentShader")
        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        return state
    }()
    
    func loadExperiment() {
        loadExperimentB()
    }
    func loadExperimentA() {
        guard size.width > 300 else { return }

        if let universe { CCUniverseRelease(universe) }
        
        let universe: UnsafeMutablePointer<CCUniverse> = CCUniverseCreate(size.width, size.height)
        CCUniverseDemarcate(universe)
        
        let ds: Double = universe.pointee.ds
        
        let dx: Double = universe.pointee.radiusBond * 0.8
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
    func loadExperimentB() {
        guard size.width > 300 else { return }

        if let universe { CCUniverseRelease(universe) }
        
        let universe: UnsafeMutablePointer<CCUniverse> = CCUniverseCreate(size.width, size.height)
        CCUniverseDemarcate(universe)
        
        let dx: Double = universe.pointee.radiusBond * 0.65
        let dr: Double = dx * sqrt(3)/2
        var dQ: Double = 2 * .pi

        var r: Double = 0
        var Q: Double = 0
        
        let maxR: Double = Double(view!.width*sqrt(2)) / 2
        let maxQ: Double = 2 * .pi
        
        var p: Bool = false
        
        while r < maxR {
            while Q < maxQ {
                let x: Double = r * cos(Q)
                let y: Double = r * sin(Q)
                CCUniverseCreateAexelAt(universe, x, y)
                Q  += dQ
            }
            r += dr
            dQ = 2 * .pi / round(r * 2 * .pi / dx)
            Q = !p ? 0 : dQ/2
            p = !p
        }
        
        CCUniverseBind(universe)
        
        self.universe = universe
    }

    func loadExperimentC() {
        guard size.width > 300 else { return }

        if let universe { CCUniverseRelease(universe) }
        
        let universe: UnsafeMutablePointer<CCUniverse> = CCUniverseCreate(size.width, size.height)
        CCUniverseDemarcate(universe)
        
        CCUniverseCreateAexelAt(universe, 0, -70);
        CCUniverseCreateAexelAt(universe, 0, -90);
        CCUniverseCreateAexelAt(universe, 12, -85);
        CCUniverseCreateAexelAt(universe, -12, -85);

        CCUniverseBind(universe)
        
        self.universe = universe
    }

    
// Events ==========================================================================================
    func onReset() { loadExperiment() }
    
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
        
        if aexels.count > 0 {
            let aexelBuffer: MTLBuffer = device.makeBuffer(bytes: aexels, length: aexels.count * MemoryLayout<MGAexelIn>.stride, options: .storageModeShared)!
            
            renderEncoder.setRenderPipelineState(aexelPipelineState)
            renderEncoder.setVertexBuffer(aexelBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: aexels.count)
        }
        
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
        
        if planets.count > 0 {
            let planetsBuffer = device.makeBuffer(bytes: planets, length: planets.count * MemoryLayout<MGCirclePacket>.stride, options: .storageModeShared)!
            
            renderEncoder.setRenderPipelineState(circlePipelineState)
            renderEncoder.setVertexBuffer(planetsBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBuffer(planetsBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: planets.count)
        }
        
    }
}
