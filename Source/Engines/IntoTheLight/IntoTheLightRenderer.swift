//
//  IntoTheLightRenderer.swift
//  Aexels
//
//  Phase 1: hex aether sliding to the left under a single centered
//  teslon.  Reuses the E&M shaders (northAetherVertexShader and
//  northLoopVertexShader) by sharing the NorthCamera / NorthLoop
//  layout defined in ElectromagnetismRenderer.swift.
//

import Acheron
import MetalKit
import simd

private struct ItLLWEContext {
    var cameraPos: SIMD2<Float>
    var cameraBounds: SIMD2<Float>
    var beta: SIMD2<Float>
}

class IntoTheLightRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let aetherPipelineState: MTLRenderPipelineState
    private let lwePipelineState: MTLRenderPipelineState
    private let loopPipelineState: MTLRenderPipelineState
    private let cameraBuffer: MTLBuffer
    private let lweBuffer: MTLBuffer
    private let backgroundTexture: MTLTexture

    weak var view: MTKView?

    /// Speed of light in points-per-second.  The aether scrolls at
    /// `velocity * c` where velocity is a fraction of c set by the slider.
    private let c: Float = 100

    /// Aether velocity as a fraction of c (range −0.99 … +0.99).
    /// Positive values slide the aether to the left under the teslon.
    var velocity: Double = 0

    private var cameraPosition: SIMD2<Float> = SIMD2<Float>(0, 0)
    private var lastTickTime: CFTimeInterval = CACurrentMediaTime()

    init?(view: MTKView) {
        self.view = view
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = commandQueue
        view.device = device

        guard let cameraBuffer = device.makeBuffer(length: MemoryLayout<NorthCamera>.size, options: .storageModeShared) else { return nil }
        self.cameraBuffer = cameraBuffer

        guard let lweBuffer = device.makeBuffer(length: MemoryLayout<ItLLWEContext>.size, options: .storageModeShared) else { return nil }
        self.lweBuffer = lweBuffer

        let library = device.makeDefaultLibrary()!

        let aetherDesc = MTLRenderPipelineDescriptor()
        aetherDesc.vertexFunction = library.makeFunction(name: "northAetherVertexShader")
        aetherDesc.fragmentFunction = library.makeFunction(name: "northAetherFragmentShader")
        aetherDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        guard let aetherState = try? device.makeRenderPipelineState(descriptor: aetherDesc) else { return nil }
        self.aetherPipelineState = aetherState

        let lweDesc = MTLRenderPipelineDescriptor()
        lweDesc.vertexFunction = library.makeFunction(name: "itlLWEVertexShader")
        lweDesc.fragmentFunction = library.makeFunction(name: "itlLWEFragmentShader")
        lweDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        lweDesc.colorAttachments[0].isBlendingEnabled = true
        lweDesc.colorAttachments[0].rgbBlendOperation = .add
        lweDesc.colorAttachments[0].alphaBlendOperation = .add
        lweDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        lweDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        lweDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        lweDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let lweState = try? device.makeRenderPipelineState(descriptor: lweDesc) else { return nil }
        self.lwePipelineState = lweState

        let loopDesc = MTLRenderPipelineDescriptor()
        loopDesc.vertexFunction = library.makeFunction(name: "northLoopVertexShader")
        loopDesc.fragmentFunction = library.makeFunction(name: "northLoopFragmentShader")
        loopDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        loopDesc.colorAttachments[0].isBlendingEnabled = true
        loopDesc.colorAttachments[0].rgbBlendOperation = .add
        loopDesc.colorAttachments[0].alphaBlendOperation = .add
        loopDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        loopDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        loopDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        loopDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let loopState = try? device.makeRenderPipelineState(descriptor: loopDesc) else { return nil }
        self.loopPipelineState = loopState

        let image = Engine.renderHex(size: CGSize(width: Screen.height, height: Screen.height))
        let textureLoader = MTKTextureLoader(device: device)
        guard let texture = try? textureLoader.newTexture(cgImage: image.cgImage!, options: [.SRGB: false]) else { return nil }
        self.backgroundTexture = texture

        super.init()
        view.delegate = self
    }

    func onReset() {
        cameraPosition = SIMD2<Float>(0, 0)
        lastTickTime = CACurrentMediaTime()
    }

    func resyncClock() { lastTickTime = CACurrentMediaTime() }

// MTKViewDelegate =================================================================================
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }

        let now = CACurrentMediaTime()
        var dt = Float(now - lastTickTime)
        lastTickTime = now
        if dt > 1.0/30 { dt = 1.0/30 }  // clamp on pause/resume

        // Advance camera so the hex aether scrolls past the centered teslon.
        if !view.isPaused { cameraPosition.x += Float(velocity) * c * dt }

        let width = Float(view.drawableSize.width / view.contentScaleFactor)
        let height = Float(view.drawableSize.height / view.contentScaleFactor)

        var camera = NorthCamera(
            position: cameraPosition,
            bounds: SIMD2<Float>(width, height),
            hexBounds: SIMD2<Float>(Float(backgroundTexture.width), Float(backgroundTexture.height)),
            velocity: SIMD2<Float>(Float(velocity) * c, 0),
            hexWidth: Float(10.0 * Screen.s * 3),
            pingVectorsOn: false,
            pongVectorsOn: false,
            photonVectorsOn: false
        )
        memcpy(cameraBuffer.contents(), &camera, MemoryLayout<NorthCamera>.size)

        var lweCtx = ItLLWEContext(
            cameraPos: cameraPosition,
            cameraBounds: SIMD2<Float>(width, height),
            beta: SIMD2<Float>(Float(velocity), 0)
        )
        memcpy(lweBuffer.contents(), &lweCtx, MemoryLayout<ItLLWEContext>.size)

        // Single teslon co-located with the camera so it stays at screen center.
        let teslon = NorthLoop(
            type: 0,
            position: cameraPosition,
            velocity: SIMD2<Float>(0, 0),
            cupola: SIMD2<Float>(0, 0),
            hyle: 1
        )
        let teslons: [NorthLoop] = [teslon]
        let loopsBuffer = device.makeBuffer(bytes: teslons, length: teslons.count * MemoryLayout<NorthLoop>.stride, options: .storageModeShared)!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(aetherPipelineState)
        encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(backgroundTexture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.setRenderPipelineState(lwePipelineState)
        encoder.setVertexBuffer(lweBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(lweBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.setRenderPipelineState(loopPipelineState)
        encoder.setVertexBuffer(cameraBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(loopsBuffer, offset: 0, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
