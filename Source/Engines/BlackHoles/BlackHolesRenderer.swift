//
//  BlackHolesRenderer.swift
//  Aexels
//
//  Phase 0 of the Black Holes lab. Uses direct softened Newtonian N-body
//  on the CPU for the two black holes -- enough to validate the Explorer
//  scaffolding, the integrator, and the rendering. Phase 1 swaps the
//  N-body step for the accelerant pipeline (Poisson solve on a grid +
//  the Aexel Equation as a velocity field).
//
//  The softened acceleration on body i is
//      a_i = sum_{j != i} G * m_j * (r_j - r_i) / (|r_j - r_i|^2 + e^2)^(3/2)
//  which matches the gradient of Phi = -sum G*m_j / sqrt(r^2 + e^2).
//

import Acheron
import MetalKit
import simd

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
    private let worldHalfWidth: Float = 1.0   // simulation spans [-1, 1] in both axes
    private let G: Float = 0.5
    private let softening: Float = 0.06
    private let dt: Float = 0.01
    private let substeps: Int = 8

    private var blackHoles: [BlackHole] = []
    private var frameCounter: Int = 0

    private var circlePipeline: MTLRenderPipelineState!

    override init?(view: MTKView) {
        super.init(view: view)
        guard let descriptor = createNormalRenderPipelineDescriptor(vertex: "bhCircleVertexShader", fragment: "bhCircleFragmentShader"),
              let state = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        circlePipeline = state
        loadDefaultExperiment()
    }

    private func loadDefaultExperiment() {
        // 3D-style Newton (Phi = -Gm/r, force ~ 1/r^2). Two equal masses M
        // separated by d, each at distance d/2 from the center of mass:
        //     v_circular = sqrt(G*M / (2*d))
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
        print("[BlackHoles] reset: G=\(G), M=\(M), d=\(d), v_circ=\(vCircular), v=\(v)")
    }

    func onReset() { loadDefaultExperiment() }

// Simulation step =================================================================================
    private func stepPhysics() {
        let dtSub = dt / Float(substeps)
        let softSq = softening * softening
        for _ in 0..<substeps {
            var accel: [SIMD2<Float>] = Array(repeating: .zero, count: blackHoles.count)
            for i in 0..<blackHoles.count {
                for j in 0..<blackHoles.count where j != i {
                    let d = blackHoles[j].position - blackHoles[i].position
                    let r2 = simd_dot(d, d) + softSq
                    let invR3 = 1.0 / (r2 * sqrt(r2))
                    accel[i] += d * (G * blackHoles[j].mass * invR3)
                }
            }
            for i in 0..<blackHoles.count {
                blackHoles[i].velocity += accel[i] * dtSub
                blackHoles[i].position += blackHoles[i].velocity * dtSub
            }
        }

        frameCounter += 1
        if frameCounter % 60 == 0 {
            for (i, bh) in blackHoles.enumerated() {
                print(String(format: "[BlackHoles] f%d bh%d pos=(%.3f, %.3f) v=(%.3f, %.3f) |v|=%.3f",
                             frameCounter, i, bh.position.x, bh.position.y,
                             bh.velocity.x, bh.velocity.y, simd_length(bh.velocity)))
            }
        }
    }

// Renderer ========================================================================================
    override func draw(renderEncoder: any MTLRenderCommandEncoder) {
        stepPhysics()
        var packets: [BHCirclePacket] = blackHoles.map { bh in
            BHCirclePacket(center: bh.position / worldHalfWidth, radius: bh.radius, color: bh.color)
        }
        guard !packets.isEmpty else { return }
        let buffer = device.makeBuffer(bytes: &packets, length: MemoryLayout<BHCirclePacket>.stride * packets.count, options: .storageModeShared)!
        renderEncoder.setRenderPipelineState(circlePipeline)
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: packets.count)
    }
}
