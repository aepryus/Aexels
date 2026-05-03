//
//  BlackHolesRenderer.swift
//  Aexels
//
//  Phase 1.1: BHs still integrated via direct softened Newton on the CPU
//  (the integrator from Phase 0), but the accelerant potential is now
//  computed analytically per cell on a 256x256 GPU texture each frame
//  and rendered as a diverging-color background under the BHs.
//
//  Per frame:
//    1. Compute step physics (CPU: softened Newton among the BHs).
//    2. Upload mass positions to a shared buffer.
//    3. Compute pass: fill Phi texture analytically per cell.
//    4. Render pass: draw background quad sampling Phi, then BH circles on top.
//

import Acheron
import MetalKit
import simd

private struct BHMass {
    var position: SIMD2<Float>   // world coordinates
    var mass: Float
    var _pad: Float = 0
}

private struct BHFieldParams {
    var worldHalfWidth: Float
    var G: Float
    var softeningSq: Float
    var massCount: UInt32
}

private struct BHSampleParams {
    var worldHalfWidth: Float
    var count: UInt32
}

private struct BHBackgroundParams {
    var scale: Float
    var _pad: SIMD3<Float> = .zero
    var deepColor: SIMD4<Float>
    var farColor: SIMD4<Float>
}

private struct BHCirclePacket {
    var center: SIMD2<Float>
    var radius: Float
    var color: SIMD4<Float>
}

private struct BlackHole {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var mass: Float
    var radius: Float
    var color: SIMD4<Float>
}

class BlackHolesRenderer: Renderer {

    // Simulation parameters
    private let worldHalfWidth: Float = 1.0
    private let G: Float = 0.5
    private let softening: Float = 0.06
    private let dt: Float = 0.01
    private let fieldGridSize: Int = 256
    // Visualization range: clamps potential to [-fieldScale, 0] for the color map.
    private let fieldScale: Float = 4.0

    private var blackHoles: [BlackHole] = []
    private var frameCounter: Int = 0

    // Pipelines
    private var phiPipeline: MTLComputePipelineState!
    private var samplePipeline: MTLComputePipelineState!
    private var backgroundPipeline: MTLRenderPipelineState!
    private var circlePipeline: MTLRenderPipelineState!

    // GPU resources
    private var phiTexture: MTLTexture!
    private var massesBuffer: MTLBuffer!
    private var accelerationsBuffer: MTLBuffer!
    private var commandQueueLocal: MTLCommandQueue!

    // Accelerations sampled on GPU at the previous frame's positions; used
    // by the next frame's integration step. Phase 1.2: BHs move via the
    // accelerant flow u = -grad(Phi), not pairwise direct Newton.
    private var lastAccelerations: [SIMD2<Float>] = []

    override init?(view: MTKView) {
        super.init(view: view)
        guard let q = device.makeCommandQueue() else { return nil }
        commandQueueLocal = q

        guard let phiFn = library.makeFunction(name: "bhComputePhi"),
              let phiState = try? device.makeComputePipelineState(function: phiFn) else { return nil }
        phiPipeline = phiState

        guard let sampleFn = library.makeFunction(name: "bhSampleAcceleration"),
              let sampleState = try? device.makeComputePipelineState(function: sampleFn) else { return nil }
        samplePipeline = sampleState

        guard let bgDesc = createNormalRenderPipelineDescriptor(vertex: "bhBackgroundVertexShader", fragment: "bhBackgroundFragmentShader"),
              let bgState = try? device.makeRenderPipelineState(descriptor: bgDesc) else { return nil }
        backgroundPipeline = bgState

        guard let circleDesc = createNormalRenderPipelineDescriptor(vertex: "bhCircleVertexShader", fragment: "bhCircleFragmentShader"),
              let circleState = try? device.makeRenderPipelineState(descriptor: circleDesc) else { return nil }
        circlePipeline = circleState

        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: fieldGridSize, height: fieldGridSize, mipmapped: false)
        texDesc.usage = [.shaderRead, .shaderWrite]
        texDesc.storageMode = .private
        phiTexture = device.makeTexture(descriptor: texDesc)
        massesBuffer = device.makeBuffer(length: MemoryLayout<BHMass>.stride * 16, options: .storageModeShared)
        accelerationsBuffer = device.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * 16, options: .storageModeShared)

        loadDefaultExperiment()
    }

    private func loadDefaultExperiment() {
        let r: Float = 0.4
        let M: Float = 1.0
        let d: Float = 2 * r
        let vCircular: Float = sqrt(G * M / (2 * d))
        let v: Float = vCircular * 0.85
        blackHoles = [
            BlackHole(position: SIMD2( r, 0), velocity: SIMD2(0,  v), mass: M, radius: 0.045, color: SIMD4(0.92, 0.4, 0.4, 1.0)),
            BlackHole(position: SIMD2(-r, 0), velocity: SIMD2(0, -v), mass: M, radius: 0.045, color: SIMD4(0.4, 0.7, 0.92, 1.0))
        ]
        frameCounter = 0
        lastAccelerations = Array(repeating: .zero, count: blackHoles.count)
        print("[BlackHoles] reset: G=\(G), M=\(M), d=\(d), v_circ=\(vCircular), v=\(v)")
    }

    func onReset() { loadDefaultExperiment() }

// Simulation step =================================================================================
    // Phase 1.2: integrate using accelerations sampled from the accelerant
    // field on the GPU at the previous frame's positions. Frame 1 uses
    // zero accelerations (BHs drift on initial velocity), then frame 2
    // onward uses the freshly-sampled u = -grad(Phi).
    private func stepPhysics() {
        // Symplectic Euler: v += a*dt, then x += v*dt. The acceleration was
        // sampled at the BH's position at the end of the previous frame on
        // the GPU, which is the standard "leapfrog half" the integrator
        // expects. No substeps -- holding a fixed across substeps would
        // under-curve the orbit and cause secular outward drift.
        for i in 0..<blackHoles.count {
            let a = i < lastAccelerations.count ? lastAccelerations[i] : .zero
            blackHoles[i].velocity += a * dt
            blackHoles[i].position += blackHoles[i].velocity * dt
        }

        frameCounter += 1
        if frameCounter % 60 == 0 {
            // Center-of-mass tracking. For two equal masses with mirror-symmetric
            // initial conditions the CoM should sit at (0, 0) forever; any drift
            // means we've leaked momentum somewhere in the pipeline.
            var com: SIMD2<Float> = .zero
            var mom: SIMD2<Float> = .zero
            var totalMass: Float = 0
            for bh in blackHoles {
                com += bh.position * bh.mass
                mom += bh.velocity * bh.mass
                totalMass += bh.mass
            }
            com /= totalMass
            mom /= totalMass
            print(String(format: "[BlackHoles] f%d com=(%.4f, %.4f) p_mean=(%.4f, %.4f)",
                         frameCounter, com.x, com.y, mom.x, mom.y))
        }
    }

    // Read the GPU-written accelerations buffer back into Swift after the
    // command buffer completes. We then subtract the mean acceleration so
    // the closed-system constraint Sum(a_i) = 0 is enforced exactly --
    // protects against secular CoM drift caused by float-precision
    // asymmetries in field sampling.
    private func readAccelerations() {
        let ptr = accelerationsBuffer.contents().assumingMemoryBound(to: SIMD2<Float>.self)
        var sampled: [SIMD2<Float>] = (0..<blackHoles.count).map { ptr[$0] }
        guard !sampled.isEmpty else { lastAccelerations = []; return }
        var totalMass: Float = 0
        var totalForce: SIMD2<Float> = .zero
        for (i, bh) in blackHoles.enumerated() {
            totalForce += sampled[i] * bh.mass
            totalMass += bh.mass
        }
        let drift = totalForce / totalMass
        for i in 0..<sampled.count { sampled[i] -= drift }
        lastAccelerations = sampled
    }

    private func uploadMasses() {
        var massStructs: [BHMass] = blackHoles.map {
            BHMass(position: $0.position, mass: $0.mass)
        }
        memcpy(massesBuffer.contents(), &massStructs, MemoryLayout<BHMass>.stride * massStructs.count)
    }

    private func computeFieldAndSample(in commandBuffer: MTLCommandBuffer) {
        guard let enc = commandBuffer.makeComputeCommandEncoder() else { return }
        // Phi field
        enc.setComputePipelineState(phiPipeline)
        enc.setTexture(phiTexture, index: 0)
        enc.setBuffer(massesBuffer, offset: 0, index: 0)
        var fieldParams = BHFieldParams(
            worldHalfWidth: worldHalfWidth,
            G: G,
            softeningSq: softening * softening,
            massCount: UInt32(blackHoles.count)
        )
        enc.setBytes(&fieldParams, length: MemoryLayout<BHFieldParams>.size, index: 1)
        let tg = MTLSize(width: 8, height: 8, depth: 1)
        let tgs = MTLSize(width: (fieldGridSize + 7) / 8, height: (fieldGridSize + 7) / 8, depth: 1)
        enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)

        // Sample u = -grad(Phi) at each BH position
        enc.setComputePipelineState(samplePipeline)
        enc.setTexture(phiTexture, index: 0)
        enc.setBuffer(massesBuffer, offset: 0, index: 0)
        enc.setBuffer(accelerationsBuffer, offset: 0, index: 1)
        var sampleParams = BHSampleParams(worldHalfWidth: worldHalfWidth, count: UInt32(blackHoles.count))
        enc.setBytes(&sampleParams, length: MemoryLayout<BHSampleParams>.size, index: 2)
        let bhTGSize = MTLSize(width: max(blackHoles.count, 1), height: 1, depth: 1)
        enc.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: bhTGSize)

        enc.endEncoding()
    }

// Renderer ========================================================================================
    // Override the base class's draw(in:) so we can interleave a compute pass
    // (Phi field) before the render pass.
    override func draw(in view: MTKView) {
        guard let commandBuffer = commandQueueLocal.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        stepPhysics()
        uploadMasses()
        computeFieldAndSample(in: commandBuffer)

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        // 1. Background field
        var bgParams = BHBackgroundParams(
            scale: fieldScale,
            deepColor: SIMD4(0.18, 0.04, 0.10, 1.0),
            farColor:  SIMD4(0.04, 0.04, 0.08, 1.0)
        )
        renderEncoder.setRenderPipelineState(backgroundPipeline)
        renderEncoder.setFragmentTexture(phiTexture, index: 0)
        renderEncoder.setFragmentBytes(&bgParams, length: MemoryLayout<BHBackgroundParams>.size, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // 2. Black holes
        var packets: [BHCirclePacket] = blackHoles.map {
            BHCirclePacket(center: $0.position / worldHalfWidth, radius: $0.radius, color: $0.color)
        }
        if !packets.isEmpty {
            let buffer = device.makeBuffer(bytes: &packets, length: MemoryLayout<BHCirclePacket>.stride * packets.count, options: .storageModeShared)!
            renderEncoder.setRenderPipelineState(circlePipeline)
            renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
            renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: packets.count)
        }

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        // Wait synchronously so lastAccelerations is guaranteed fresh on
        // the next frame's stepPhysics. async addCompletedHandler can
        // race with the next draw call and leave momentum unconserved.
        commandBuffer.waitUntilCompleted()
        readAccelerations()
    }

    // The base class abstract draw(renderEncoder:) is unused now since we
    // override draw(in:) directly. Provide a no-op so the override chain
    // is satisfied.
    override func draw(renderEncoder: any MTLRenderCommandEncoder) {}
}
