//
//  BlackHolesRenderer.swift
//  Aexels
//
//  Phase 1.3: Φ heatmap background + tracer particles drifting through
//  u = -∇Φ. The BHs are integrated by sampling u at their world position
//  on the GPU each frame (Phase 1.2 momentum-conserved integration).
//
//  Per frame:
//    1. CPU integrate BHs using last frame's GPU-sampled accelerations.
//    2. Upload mass positions.
//    3. Compute pass: Φ → u → sample u at BH positions; advect particles.
//    4. Render pass: Φ background → particle streaks → BH disks.
//    5. Read back accelerations (with mean-force subtraction).
//
//  The dynamic v_a (Aexel Equation) field is deferred to Phase 1.4. Without
//  the −ε∇²v_a viscosity term it has no equilibrium and grows unboundedly,
//  so there's nothing meaningful to display until viscosity is introduced.
//

import Acheron
import MetalKit
import simd

private struct BHMass {
    var position: SIMD2<Float>
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

// Layout note: Metal aligns float4 to 16, so scale + 12 bytes of pad must
// sit before deepColor. Using 3 Float pads (12 bytes) matches Metal's
// natural offset; SIMD3<Float> would have Swift stride 16 and slide every
// subsequent field forward by 4 bytes, swapping deepColor/farColor.
private struct BHBackgroundParams {
    var scale: Float
    var _p0: Float = 0
    var _p1: Float = 0
    var _p2: Float = 0
    var deepColor: SIMD4<Float>
    var farColor: SIMD4<Float>
}

private struct BHParticle {
    var position: SIMD2<Float>
    var prevPosition: SIMD2<Float>
    var age: Float
    var life: Float
}

private struct BHParticleParams {
    var worldHalfWidth: Float
    var dt: Float
    var cMax: Float          // speed-of-light cap on |u| sampled by particles
    var frameSeed: UInt32
    var count: UInt32
}

private struct BHVAetherParams {
    var worldHalfWidth: Float
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
    private let fieldScale: Float = 4.0
    private let particleCount: Int = 1024
    private let particleDt: Float = 0.0035
    private let cMax: Float = 10.0   // speed-of-light cap (particle viz only)

    private var blackHoles: [BlackHole] = []
    private var frameCounter: Int = 0

    // Visualization toggles wired to the controls tab.
    var wellsOn: Bool = true
    var flowOn: Bool = true
    // Phase 1.4: ad-hoc Stokes drag on each BH representing aether
    // dissipation at leading order. F_drag = -dragGamma * v_BH; the
    // orbital energy decays into the (implicit) v_a field. Zero
    // disables drag entirely, so the slider doubles as on/off.
    var dragGamma: Float = 0

    // Pipelines
    private var phiPipeline: MTLComputePipelineState!
    private var samplePipeline: MTLComputePipelineState!
    private var computeUPipeline: MTLComputePipelineState!
    private var vAetherPipeline: MTLComputePipelineState!
    private var particlePipeline: MTLComputePipelineState!
    private var backgroundPipeline: MTLRenderPipelineState!
    private var particleRenderPipeline: MTLRenderPipelineState!
    private var circlePipeline: MTLRenderPipelineState!

    // GPU resources
    private var phiTexture: MTLTexture!
    private var uTexture: MTLTexture!
    private var vaTexture: MTLTexture!   // algebraic aether velocity field, recomputed each frame
    private var massesBuffer: MTLBuffer!
    private var accelerationsBuffer: MTLBuffer!
    private var particlesBuffer: MTLBuffer!
    private var commandQueueLocal: MTLCommandQueue!

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

        guard let uFn = library.makeFunction(name: "bhComputeU"),
              let uState = try? device.makeComputePipelineState(function: uFn) else { return nil }
        computeUPipeline = uState

        guard let particleFn = library.makeFunction(name: "bhUpdateParticles"),
              let particleState = try? device.makeComputePipelineState(function: particleFn) else { return nil }
        particlePipeline = particleState

        guard let vAetherFn = library.makeFunction(name: "bhComputeVAether"),
              let vAetherState = try? device.makeComputePipelineState(function: vAetherFn) else { return nil }
        vAetherPipeline = vAetherState

        guard let bgDesc = createNormalRenderPipelineDescriptor(vertex: "bhBackgroundVertexShader", fragment: "bhBackgroundFragmentShader"),
              let bgState = try? device.makeRenderPipelineState(descriptor: bgDesc) else { return nil }
        backgroundPipeline = bgState

        guard let pDesc = createNormalRenderPipelineDescriptor(vertex: "bhParticleVertexShader", fragment: "bhParticleFragmentShader"),
              let pState = try? device.makeRenderPipelineState(descriptor: pDesc) else { return nil }
        particleRenderPipeline = pState

        guard let circleDesc = createNormalRenderPipelineDescriptor(vertex: "bhCircleVertexShader", fragment: "bhCircleFragmentShader"),
              let circleState = try? device.makeRenderPipelineState(descriptor: circleDesc) else { return nil }
        circlePipeline = circleState

        let scalarDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: fieldGridSize, height: fieldGridSize, mipmapped: false)
        scalarDesc.usage = [.shaderRead, .shaderWrite]
        scalarDesc.storageMode = .private
        phiTexture = device.makeTexture(descriptor: scalarDesc)

        let vectorDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rg32Float, width: fieldGridSize, height: fieldGridSize, mipmapped: false)
        vectorDesc.usage = [.shaderRead, .shaderWrite]
        vectorDesc.storageMode = .private
        uTexture = device.makeTexture(descriptor: vectorDesc)
        vaTexture = device.makeTexture(descriptor: vectorDesc)

        massesBuffer = device.makeBuffer(length: MemoryLayout<BHMass>.stride * 16, options: .storageModeShared)
        accelerationsBuffer = device.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * 16, options: .storageModeShared)
        particlesBuffer = device.makeBuffer(length: MemoryLayout<BHParticle>.stride * particleCount, options: .storageModeShared)

        seedParticles()
        loadDefaultExperiment()
    }

    private func seedParticles() {
        let ptr = particlesBuffer.contents().assumingMemoryBound(to: BHParticle.self)
        for i in 0..<particleCount {
            let x = Float.random(in: -worldHalfWidth...worldHalfWidth)
            let y = Float.random(in: -worldHalfWidth...worldHalfWidth)
            let pos = SIMD2<Float>(x, y)
            ptr[i] = BHParticle(
                position: pos,
                prevPosition: pos,
                age: Float.random(in: 0...50),
                life: Float.random(in: 30...90)
            )
        }
    }

    private func loadDefaultExperiment() {
        let r: Float = 0.4
        let M: Float = 1.0
        let d: Float = 2 * r
        let vCircular: Float = sqrt(G * M / (2 * d))
        let v: Float = vCircular * 0.85
        blackHoles = [
            BlackHole(position: SIMD2( r, 0), velocity: SIMD2(0,  v), mass: M, radius: 0.045, color: SIMD4(0, 0, 0, 1.0)),
            BlackHole(position: SIMD2(-r, 0), velocity: SIMD2(0, -v), mass: M, radius: 0.045, color: SIMD4(0, 0, 0, 1.0))
        ]
        frameCounter = 0
        lastAccelerations = Array(repeating: .zero, count: blackHoles.count)
    }

    func onReset() {
        seedParticles()
        loadDefaultExperiment()
    }

// Simulation step =================================================================================
    private func stepPhysics() {
        for i in 0..<blackHoles.count {
            var a = i < lastAccelerations.count ? lastAccelerations[i] : .zero
            a -= dragGamma * blackHoles[i].velocity
            blackHoles[i].velocity += a * dt
            blackHoles[i].position += blackHoles[i].velocity * dt
        }
        frameCounter += 1
    }

    // Mean-force subtraction enforces Σ a_i = 0 (Newton's 3rd law) so any
    // float-precision asymmetry in field sampling can't leak momentum.
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

    private func computeFieldAndAdvect(in commandBuffer: MTLCommandBuffer) {
        guard let enc = commandBuffer.makeComputeCommandEncoder() else { return }
        let tg = MTLSize(width: 8, height: 8, depth: 1)
        let tgs = MTLSize(width: (fieldGridSize + 7) / 8, height: (fieldGridSize + 7) / 8, depth: 1)

        // 1) Phi field
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
        enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
        enc.memoryBarrier(scope: .textures)

        // 2) u = -grad(Phi) on grid
        enc.setComputePipelineState(computeUPipeline)
        enc.setTexture(phiTexture, index: 0)
        enc.setTexture(uTexture, index: 1)
        enc.setBytes(&fieldParams, length: MemoryLayout<BHFieldParams>.size, index: 0)
        enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
        enc.memoryBarrier(scope: .textures)

        // 3) Aether velocity: algebraic equilibrium v = √(2|Φ|) · (-∇Φ/|∇Φ|)
        enc.setComputePipelineState(vAetherPipeline)
        enc.setTexture(phiTexture, index: 0)
        enc.setTexture(vaTexture, index: 1)
        var vAetherParams = BHVAetherParams(worldHalfWidth: worldHalfWidth)
        enc.setBytes(&vAetherParams, length: MemoryLayout<BHVAetherParams>.size, index: 0)
        enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
        enc.memoryBarrier(scope: .textures)

        // 4) Sample u at each BH position into accelerations buffer
        enc.setComputePipelineState(samplePipeline)
        enc.setTexture(phiTexture, index: 0)
        enc.setBuffer(massesBuffer, offset: 0, index: 0)
        enc.setBuffer(accelerationsBuffer, offset: 0, index: 1)
        var sampleParams = BHSampleParams(worldHalfWidth: worldHalfWidth, count: UInt32(blackHoles.count))
        enc.setBytes(&sampleParams, length: MemoryLayout<BHSampleParams>.size, index: 2)
        let bhTGSize = MTLSize(width: max(blackHoles.count, 1), height: 1, depth: 1)
        enc.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: bhTGSize)

        // 5) Advect tracer particles through v_aether (the actual aether velocity)
        enc.setComputePipelineState(particlePipeline)
        enc.setBuffer(particlesBuffer, offset: 0, index: 0)
        enc.setTexture(vaTexture, index: 0)
        var particleParams = BHParticleParams(
            worldHalfWidth: worldHalfWidth,
            dt: particleDt,
            cMax: cMax,
            frameSeed: UInt32(truncatingIfNeeded: frameCounter &* 2654435761),
            count: UInt32(particleCount)
        )
        enc.setBytes(&particleParams, length: MemoryLayout<BHParticleParams>.size, index: 1)
        let pTG = MTLSize(width: 64, height: 1, depth: 1)
        let pGroups = MTLSize(width: (particleCount + 63) / 64, height: 1, depth: 1)
        enc.dispatchThreadgroups(pGroups, threadsPerThreadgroup: pTG)

        enc.endEncoding()
    }

// Renderer ========================================================================================
    override func draw(in view: MTKView) {
        guard let commandBuffer = commandQueueLocal.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        stepPhysics()
        uploadMasses()
        computeFieldAndAdvect(in: commandBuffer)

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        // 1. Phi heatmap background
        if wellsOn {
            var bgParams = BHBackgroundParams(
                scale: fieldScale,
                deepColor: SIMD4(0.65, 0.30, 0.95, 1.0),  // bright cosmic purple
                farColor:  SIMD4(0.02, 0.02, 0.05, 1.0)
            )
            renderEncoder.setRenderPipelineState(backgroundPipeline)
            renderEncoder.setFragmentTexture(phiTexture, index: 0)
            renderEncoder.setFragmentBytes(&bgParams, length: MemoryLayout<BHBackgroundParams>.size, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        // 2. Particle streaks (one line per particle: prevPosition → position)
        if flowOn {
            var halfW: Float = worldHalfWidth
            renderEncoder.setRenderPipelineState(particleRenderPipeline)
            renderEncoder.setVertexBuffer(particlesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&halfW, length: MemoryLayout<Float>.size, index: 1)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2, instanceCount: particleCount)
        }

        // 3. Black holes
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
        // Wait synchronously so lastAccelerations is fresh on the next frame.
        commandBuffer.waitUntilCompleted()
        readAccelerations()
    }

    override func draw(renderEncoder: any MTLRenderCommandEncoder) {}
}
