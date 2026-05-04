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
    var velocity: SIMD2<Float>   // used by matter; ignored by flow particles
    var age: Float
    var life: Float
}

private struct BHParticleParams {
    var worldHalfWidth: Float
    var dt: Float
    var cMax: Float
    var frameSeed: UInt32
    var count: UInt32
}

private struct BHMatterParams {
    var worldHalfWidth: Float
    var dt: Float
    var cMax: Float
    var frameSeed: UInt32
    var count: UInt32
    var G: Float
    var totalMass: Float
}

private struct BHVAetherParams {
    var worldHalfWidth: Float
}

private struct BHWaveParams {
    var worldHalfWidth: Float
    var c: Float
    var dt: Float
    var gamma: Float
}

private struct BHSpongeParams {
    var width: UInt32
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
    private let particleCountFlow: Int = 1024     // aether and accelerant each
    private let particleCountMatter: Int = 512
    private let particleDt: Float = 0.0035
    private let matterDt: Float = 0.01            // matter integrates u over its trajectory
    private let cMax: Float = 10.0                // speed-of-light cap

    // Wave-equation accelerant (Phase 1: dynamic Φ)
    // CFL for 2D 5-point wave: c·dt_sub/dx ≤ 1/√2 ≈ 0.707. With c=10, dx=2/256:
    // dt_sub_max ≈ 5.5e-4. So K ≥ ceil(0.01 / 5.5e-4) ≈ 18. Using 32 for margin
    // (CFL = 0.4, well inside stability region).
    private let waveSubsteps: Int = 32
    private let spongeWidth: UInt32 = 16           // sponge layer thickness in cells

    var dynamicAccelerantOn: Bool = true    // wave-equation Φ; toggle off in UI to fall back to analytical
    var aetherOn: Bool = true
    var accelerantOn: Bool = false
    var matterOn: Bool = false

    private var blackHoles: [BlackHole] = []
    private var frameCounter: Int = 0
    private var phiInitialized: Bool = false   // dynamic Φ first-frame init flag

    // Visualization toggles wired to the controls tab.
    var wellsOn: Bool = true
    // Phase 1.4: ad-hoc Stokes drag on each BH representing aether
    // dissipation at leading order. F_drag = -dragGamma * v_BH; the
    // orbital energy decays into the (implicit) v_a field. Zero
    // disables drag entirely, so the slider doubles as on/off.
    var dragGamma: Float = 0

    // Pipelines
    private var phiPipeline: MTLComputePipelineState!         // analytical Φ_static
    private var sourcePipeline: MTLComputePipelineState!      // S = ∇²Φ_static
    private var evolvePhiPipeline: MTLComputePipelineState!   // wave-equation leapfrog
    private var spongePipeline: MTLComputePipelineState!      // absorbing boundary
    private var copyPhiPipeline: MTLComputePipelineState!     // initialize Φ_dyn ← Φ_static
    private var samplePipeline: MTLComputePipelineState!
    private var computeUPipeline: MTLComputePipelineState!
    private var vAetherPipeline: MTLComputePipelineState!
    private var flowParticlePipeline: MTLComputePipelineState!
    private var matterParticlePipeline: MTLComputePipelineState!
    private var backgroundPipeline: MTLRenderPipelineState!
    private var particleRenderPipeline: MTLRenderPipelineState!
    private var circlePipeline: MTLRenderPipelineState!

    // GPU resources
    private var phiStaticTexture: MTLTexture!     // analytical Φ from current masses
    private var phiTexture: MTLTexture!           // alias to whichever ping-pong holds latest dynamic Φ
    private var phiA: MTLTexture!                 // ping-pong A
    private var phiB: MTLTexture!                 // ping-pong B
    private var phiC: MTLTexture!                 // ping-pong C (3rd needed for leapfrog: prev/curr/new)
    private var sourceTexture: MTLTexture!        // S = ∇²Φ_static
    // Live pointers cycled each substep
    private var phiPrev: MTLTexture!
    private var phiCurr: MTLTexture!
    private var phiNew: MTLTexture!
    private var uTexture: MTLTexture!
    private var vaTexture: MTLTexture!   // algebraic aether velocity field, recomputed each frame
    private var massesBuffer: MTLBuffer!
    private var accelerationsBuffer: MTLBuffer!
    private var aetherParticlesBuffer: MTLBuffer!
    private var accelerantParticlesBuffer: MTLBuffer!
    private var matterParticlesBuffer: MTLBuffer!
    private var phiStaticReadback: MTLBuffer!     // for diagnostics: Φ_static dump
    private var phiDynReadback: MTLBuffer!         // for diagnostics: Φ_dyn dump
    private var commandQueueLocal: MTLCommandQueue!

    private var lastAccelerations: [SIMD2<Float>] = []

    override init?(view: MTKView) {
        super.init(view: view)
        guard let q = device.makeCommandQueue() else { return nil }
        commandQueueLocal = q

        guard let phiFn = library.makeFunction(name: "bhComputePhi"),
              let phiState = try? device.makeComputePipelineState(function: phiFn) else { return nil }
        phiPipeline = phiState

        guard let sourceFn = library.makeFunction(name: "bhComputeSource"),
              let sourceState = try? device.makeComputePipelineState(function: sourceFn) else { return nil }
        sourcePipeline = sourceState

        guard let evolveFn = library.makeFunction(name: "bhEvolvePhi"),
              let evolveState = try? device.makeComputePipelineState(function: evolveFn) else { return nil }
        evolvePhiPipeline = evolveState

        guard let spongeFn = library.makeFunction(name: "bhSpongePhi"),
              let spongeState = try? device.makeComputePipelineState(function: spongeFn) else { return nil }
        spongePipeline = spongeState

        guard let copyFn = library.makeFunction(name: "bhCopyPhi"),
              let copyState = try? device.makeComputePipelineState(function: copyFn) else { return nil }
        copyPhiPipeline = copyState

        guard let sampleFn = library.makeFunction(name: "bhSampleAcceleration"),
              let sampleState = try? device.makeComputePipelineState(function: sampleFn) else { return nil }
        samplePipeline = sampleState

        guard let uFn = library.makeFunction(name: "bhComputeU"),
              let uState = try? device.makeComputePipelineState(function: uFn) else { return nil }
        computeUPipeline = uState

        guard let flowFn = library.makeFunction(name: "bhUpdateFlowParticles"),
              let flowState = try? device.makeComputePipelineState(function: flowFn) else { return nil }
        flowParticlePipeline = flowState

        guard let matterFn = library.makeFunction(name: "bhUpdateMatterParticles"),
              let matterState = try? device.makeComputePipelineState(function: matterFn) else { return nil }
        matterParticlePipeline = matterState

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
        phiStaticTexture = device.makeTexture(descriptor: scalarDesc)
        sourceTexture    = device.makeTexture(descriptor: scalarDesc)
        phiA = device.makeTexture(descriptor: scalarDesc)
        phiB = device.makeTexture(descriptor: scalarDesc)
        phiC = device.makeTexture(descriptor: scalarDesc)
        phiPrev = phiA
        phiCurr = phiB
        phiNew  = phiC
        phiTexture = phiCurr   // alias for consumers (sample, gradient, render)

        let vectorDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rg32Float, width: fieldGridSize, height: fieldGridSize, mipmapped: false)
        vectorDesc.usage = [.shaderRead, .shaderWrite]
        vectorDesc.storageMode = .private
        uTexture = device.makeTexture(descriptor: vectorDesc)
        vaTexture = device.makeTexture(descriptor: vectorDesc)

        let phiBytesPerRow = fieldGridSize * MemoryLayout<Float>.stride
        let phiTotalBytes = phiBytesPerRow * fieldGridSize
        phiStaticReadback = device.makeBuffer(length: phiTotalBytes, options: .storageModeShared)
        phiDynReadback    = device.makeBuffer(length: phiTotalBytes, options: .storageModeShared)

        massesBuffer = device.makeBuffer(length: MemoryLayout<BHMass>.stride * 16, options: .storageModeShared)
        accelerationsBuffer = device.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * 16, options: .storageModeShared)
        aetherParticlesBuffer = device.makeBuffer(length: MemoryLayout<BHParticle>.stride * particleCountFlow, options: .storageModeShared)
        accelerantParticlesBuffer = device.makeBuffer(length: MemoryLayout<BHParticle>.stride * particleCountFlow, options: .storageModeShared)
        matterParticlesBuffer = device.makeBuffer(length: MemoryLayout<BHParticle>.stride * particleCountMatter, options: .storageModeShared)

        seedAllParticles()
        loadDefaultExperiment()
    }

    private func seedAllParticles() {
        seedFlowParticles(buffer: aetherParticlesBuffer, count: particleCountFlow)
        seedFlowParticles(buffer: accelerantParticlesBuffer, count: particleCountFlow)
        seedMatterParticles(buffer: matterParticlesBuffer, count: particleCountMatter)
    }

    private func seedFlowParticles(buffer: MTLBuffer, count: Int) {
        let ptr = buffer.contents().assumingMemoryBound(to: BHParticle.self)
        for i in 0..<count {
            let pos = SIMD2<Float>(.random(in: -worldHalfWidth...worldHalfWidth),
                                   .random(in: -worldHalfWidth...worldHalfWidth))
            ptr[i] = BHParticle(
                position: pos,
                prevPosition: pos,
                velocity: .zero,
                age: Float.random(in: 0...50),
                life: Float.random(in: 30...90)
            )
        }
    }

    private func seedMatterParticles(buffer: MTLBuffer, count: Int) {
        let ptr = buffer.contents().assumingMemoryBound(to: BHParticle.self)
        let totalMass = blackHoles.reduce(Float(0)) { $0 + $1.mass }
        let M = totalMass > 0 ? totalMass : 2
        for i in 0..<count {
            let pos = SIMD2<Float>(.random(in: -worldHalfWidth...worldHalfWidth),
                                   .random(in: -worldHalfWidth...worldHalfWidth))
            let r = max(simd_length(pos), 0.15)
            let posClamped = simd_length(pos) < 0.15 ? pos * (0.15 / simd_length(pos)) : pos
            let dirSign: Float = Bool.random() ? 1 : -1
            let tangent = SIMD2<Float>(-posClamped.y, posClamped.x) / r * dirSign
            let vCirc = sqrt(G * M / r) * Float.random(in: 0.3...0.95)
            ptr[i] = BHParticle(
                position: posClamped,
                prevPosition: posClamped,
                velocity: tangent * vCirc,
                age: Float.random(in: 0...100),
                life: Float.random(in: 60...300)
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
        phiInitialized = false
        lastAccelerations = Array(repeating: .zero, count: blackHoles.count)
    }

    func onReset() {
        loadDefaultExperiment()
        seedAllParticles()
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

        // 1a) Φ_static — analytical potential from current mass positions.
        //     Used to compute the wave-equation source S = ∇²Φ_static.
        enc.setComputePipelineState(phiPipeline)
        enc.setTexture(phiStaticTexture, index: 0)
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

        if dynamicAccelerantOn {
            // 1b) First-frame init: Φ_dyn ← Φ_static for both phiCurr and phiPrev,
            //     so the leapfrog starts at equilibrium with zero time derivative.
            if !phiInitialized {
                enc.setComputePipelineState(copyPhiPipeline)
                enc.setTexture(phiStaticTexture, index: 0)
                enc.setTexture(phiCurr, index: 1)
                enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
                enc.memoryBarrier(scope: .textures)
                enc.setTexture(phiStaticTexture, index: 0)
                enc.setTexture(phiPrev, index: 1)
                enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
                enc.memoryBarrier(scope: .textures)
                phiInitialized = true
            }

            // 1c) Source S = ∇²Φ_static for the wave equation.
            enc.setComputePipelineState(sourcePipeline)
            enc.setTexture(phiStaticTexture, index: 0)
            enc.setTexture(sourceTexture, index: 1)
            enc.setBytes(&fieldParams, length: MemoryLayout<BHFieldParams>.size, index: 0)
            enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
            enc.memoryBarrier(scope: .textures)

            // 1d) Wave equation: ∂²Φ/∂t² = c²(∇²Φ − S). Leapfrog with K substeps
            //     to satisfy CFL dt_sub < dx/c. Three-buffer rotation for prev/curr/new.
            let dtWave = dt / Float(waveSubsteps)
            // γ damping: suppress checkerboard modes. Tune for stability vs. signal preservation.
            // γ tuned by iteration: γ=500 unstable (f7 corner blowup), γ=1000 slow blowup
            // (~9s to NaN), γ=2000 stable indefinitely with diff ~0.17 (2% rel err).
            var waveParams = BHWaveParams(worldHalfWidth: worldHalfWidth, c: cMax, dt: dtWave, gamma: 2000.0)
            for _ in 0..<waveSubsteps {
                enc.setComputePipelineState(evolvePhiPipeline)
                enc.setTexture(phiCurr, index: 0)
                enc.setTexture(phiPrev, index: 1)
                enc.setTexture(sourceTexture, index: 2)
                enc.setTexture(phiNew, index: 3)
                enc.setBytes(&waveParams, length: MemoryLayout<BHWaveParams>.size, index: 0)
                enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
                enc.memoryBarrier(scope: .textures)
                // Rotate: phiPrev <- phiCurr, phiCurr <- phiNew, phiNew <- (old phiPrev)
                let tempPrev = phiPrev
                phiPrev = phiCurr
                phiCurr = phiNew
                phiNew  = tempPrev
            }

            // 1e) Sponge: blend phiCurr toward Φ_static near edges so outgoing
            //     waves are absorbed instead of reflecting. Writes through phiNew,
            //     then we cycle so phiCurr ends up holding the sponged Φ.
            enc.setComputePipelineState(spongePipeline)
            enc.setTexture(phiStaticTexture, index: 0)
            enc.setTexture(phiCurr, index: 1)
            enc.setTexture(phiNew, index: 2)
            var spongeParams = BHSpongeParams(width: spongeWidth)
            enc.setBytes(&spongeParams, length: MemoryLayout<BHSpongeParams>.size, index: 0)
            enc.dispatchThreadgroups(tgs, threadsPerThreadgroup: tg)
            enc.memoryBarrier(scope: .textures)
            // After sponge, phiNew has the canonical "current" Φ. Cycle so phiCurr
            // holds it for downstream consumers.
            let tempPrev2 = phiPrev
            phiPrev = phiCurr
            phiCurr = phiNew
            phiNew  = tempPrev2

            phiTexture = phiCurr
        } else {
            // Analytical engine: bypass wave equation entirely. Consumers read
            // from phiStaticTexture directly. Reset init flag so the wave engine
            // re-initializes cleanly when re-enabled.
            phiTexture = phiStaticTexture
            phiInitialized = false
        }

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

        // 5) Advect tracer particles. Three independent particle systems:
        //    aether (rides v_aether), accelerant (rides u), matter (Newton).
        let pTG = MTLSize(width: 64, height: 1, depth: 1)

        if aetherOn {
            enc.setComputePipelineState(flowParticlePipeline)
            enc.setBuffer(aetherParticlesBuffer, offset: 0, index: 0)
            enc.setTexture(vaTexture, index: 0)
            var pp = BHParticleParams(
                worldHalfWidth: worldHalfWidth,
                dt: particleDt,
                cMax: cMax,
                frameSeed: UInt32(truncatingIfNeeded: frameCounter &* 2654435761),
                count: UInt32(particleCountFlow)
            )
            enc.setBytes(&pp, length: MemoryLayout<BHParticleParams>.size, index: 1)
            enc.dispatchThreadgroups(MTLSize(width: (particleCountFlow + 63) / 64, height: 1, depth: 1), threadsPerThreadgroup: pTG)
        }

        if accelerantOn {
            enc.setComputePipelineState(flowParticlePipeline)
            enc.setBuffer(accelerantParticlesBuffer, offset: 0, index: 0)
            enc.setTexture(uTexture, index: 0)
            var pp = BHParticleParams(
                worldHalfWidth: worldHalfWidth,
                dt: particleDt,
                cMax: cMax,
                frameSeed: UInt32(truncatingIfNeeded: (frameCounter &+ 7) &* 2654435761),
                count: UInt32(particleCountFlow)
            )
            enc.setBytes(&pp, length: MemoryLayout<BHParticleParams>.size, index: 1)
            enc.dispatchThreadgroups(MTLSize(width: (particleCountFlow + 63) / 64, height: 1, depth: 1), threadsPerThreadgroup: pTG)
        }

        if matterOn {
            let totalMass = blackHoles.reduce(Float(0)) { $0 + $1.mass }
            enc.setComputePipelineState(matterParticlePipeline)
            enc.setBuffer(matterParticlesBuffer, offset: 0, index: 0)
            enc.setTexture(uTexture, index: 0)
            var mp = BHMatterParams(
                worldHalfWidth: worldHalfWidth,
                dt: matterDt,
                cMax: cMax,
                frameSeed: UInt32(truncatingIfNeeded: (frameCounter &+ 13) &* 2654435761),
                count: UInt32(particleCountMatter),
                G: G,
                totalMass: totalMass > 0 ? totalMass : 2
            )
            enc.setBytes(&mp, length: MemoryLayout<BHMatterParams>.size, index: 1)
            enc.dispatchThreadgroups(MTLSize(width: (particleCountMatter + 63) / 64, height: 1, depth: 1), threadsPerThreadgroup: pTG)
        }

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

        // 2. Particle streaks for the three flows. Each is a separate
        //    instanced line draw with its own buffer and color.
        var halfW: Float = worldHalfWidth
        renderEncoder.setRenderPipelineState(particleRenderPipeline)
        renderEncoder.setVertexBytes(&halfW, length: MemoryLayout<Float>.size, index: 1)

        if aetherOn {
            var color = SIMD4<Float>(0.95, 0.95, 1.00, 0.55)   // soft white — aether
            renderEncoder.setVertexBuffer(aetherParticlesBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2, instanceCount: particleCountFlow)
        }
        if accelerantOn {
            var color = SIMD4<Float>(1.00, 0.65, 0.20, 0.65)   // amber — accelerant
            renderEncoder.setVertexBuffer(accelerantParticlesBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2, instanceCount: particleCountFlow)
        }
        if matterOn {
            var color = SIMD4<Float>(0.50, 0.95, 0.55, 0.85)   // green — matter
            renderEncoder.setVertexBuffer(matterParticlesBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2, instanceCount: particleCountMatter)
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

        // Diagnostic blit once per second.
        if frameCounter % 60 == 0 {
            if let blit = commandBuffer.makeBlitCommandEncoder() {
                let bpr = fieldGridSize * MemoryLayout<Float>.stride
                let size = MTLSize(width: fieldGridSize, height: fieldGridSize, depth: 1)
                let origin = MTLOrigin(x: 0, y: 0, z: 0)
                blit.copy(from: phiStaticTexture, sourceSlice: 0, sourceLevel: 0,
                          sourceOrigin: origin, sourceSize: size,
                          to: phiStaticReadback, destinationOffset: 0,
                          destinationBytesPerRow: bpr,
                          destinationBytesPerImage: bpr * fieldGridSize)
                blit.copy(from: phiTexture, sourceSlice: 0, sourceLevel: 0,
                          sourceOrigin: origin, sourceSize: size,
                          to: phiDynReadback, destinationOffset: 0,
                          destinationBytesPerRow: bpr,
                          destinationBytesPerImage: bpr * fieldGridSize)
                blit.endEncoding()
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
        // Wait synchronously so lastAccelerations is fresh on the next frame.
        commandBuffer.waitUntilCompleted()
        readAccelerations()
        logPhiStats()
    }

    private func logPhiStats() {
        guard frameCounter % 60 == 0 else { return }
        let n = fieldGridSize * fieldGridSize
        let sPtr = phiStaticReadback.contents().assumingMemoryBound(to: Float.self)
        let dPtr = phiDynReadback.contents().assumingMemoryBound(to: Float.self)
        var sMin: Float = .infinity, sMax: Float = -.infinity, sSum: Double = 0
        var dMin: Float = .infinity, dMax: Float = -.infinity, dSum: Double = 0
        var sNaN = 0, dNaN = 0
        var diffMax: Float = 0, diffSumSq: Double = 0
        var diffMaxIdx = 0
        for i in 0..<n {
            let s = sPtr[i], d = dPtr[i]
            if s.isFinite { if s < sMin { sMin = s }; if s > sMax { sMax = s }; sSum += Double(s) } else { sNaN += 1 }
            if d.isFinite { if d < dMin { dMin = d }; if d > dMax { dMax = d }; dSum += Double(d) } else { dNaN += 1 }
            if s.isFinite && d.isFinite {
                let diff = abs(d - s)
                if diff > diffMax { diffMax = diff; diffMaxIdx = i }
                diffSumSq += Double(diff) * Double(diff)
            }
        }
        let sMean = Float(sSum / Double(max(1, n - sNaN)))
        let dMean = Float(dSum / Double(max(1, n - dNaN)))
        let rms   = Float((diffSumSq / Double(n)).squareRoot())
        let mx = diffMaxIdx % fieldGridSize, my = diffMaxIdx / fieldGridSize
        let mode = dynamicAccelerantOn ? "dyn" : "ana"
        let line = String(format: "[Φ %@] f%-5d static[%.2f..%.2f m=%.2f nan=%d] dyn[%.2f..%.2f m=%.2f nan=%d] diff[max=%.3e rms=%.3e at(%d,%d)]\n",
                          mode, frameCounter, sMin, sMax, sMean, sNaN, dMin, dMax, dMean, dNaN, diffMax, rms, mx, my)
        if let data = line.data(using: .utf8) {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aexels_phi.log")
            if FileManager.default.fileExists(atPath: url.path) {
                if let h = try? FileHandle(forWritingTo: url) {
                    h.seekToEndOfFile(); h.write(data); try? h.close()
                }
            } else {
                try? data.write(to: url)
            }
        }
    }

    override func draw(renderEncoder: any MTLRenderCommandEncoder) {}
}
