//
//  RenderSky.swift
//  DeepMuse
//
//  Created by warren on 9/14/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//


#if os(xrOS)
import CompositorServices
import Metal
import MetalKit
import simd
import Spatial

//enum BufferIndex: Int {
//    case meshPositions = 0
//    case meshGenerics  = 1
//    case uniforms      = 2
//}
//
//enum VertexAttribute: Int {
//
//    case position = 0
//    case texcoord = 1
//}
//enum TextureIndex: Int {
//
//    case color    = 0
//}
//
//struct Uniforms {
//    let projectionMatrix:  simd_float4x4
//    let modelViewMatrix: simd_float4x4
//}
//typealias UniformsArray = (Uniforms,Uniforms)

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<UniformsArray>.size + 0xFF) & -0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

extension LayerRenderer.Clock.Instant.Duration {
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}

class RenderSky {

    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var dynamicUniformBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var colorMap: MTLTexture

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<UniformsArray>

    var rotation: Float = 0
    var mesh: MTKMesh

    let arSession: ARKitSession
    let worldTracking: WorldTrackingProvider
    let layerRenderer: LayerRenderer

    init(_ layerRenderer: LayerRenderer) {
        self.layerRenderer = layerRenderer
        self.device = layerRenderer.device
        self.commandQueue = self.device.makeCommandQueue()!

        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight

        self.dynamicUniformBuffer = self.device.makeBuffer(length:uniformBufferSize,
                                                           options:[MTLResourceOptions.storageModeShared])!

        self.dynamicUniformBuffer.label = "UniformBuffer"

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:UniformsArray.self, capacity:1)

        let mtlVertexDescriptor = RenderSky.buildMetalVertexDescriptor()

        do {
            pipelineState = try RenderSky.buildRenderPipelineWithDevice(device: device,
                                                                       layerRenderer: layerRenderer,
                                                                       mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            fatalError("Unable to compile render pipeline state.  Error info: \(error)")
        }

        let stencil = MTLDepthStencilDescriptor()
        stencil.depthCompareFunction = MTLCompareFunction.greater
        stencil.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor:stencil)!

        do {
            mesh = try RenderSky.buildMesh(device: device, mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            fatalError("Unable to build MetalKit Mesh. Error info: \(error)")
        }

        do {
            colorMap = try RenderSky.loadTexture(device: device, textureName: "ColorMap")
        } catch {
            fatalError("Unable to load texture. Error info: \(error)")
        }

        worldTracking = WorldTrackingProvider()
        arSession = ARKitSession()
    }

    func startRenderLoop() {
        Task {
            do {
                try await arSession.run([worldTracking])
            } catch {
                fatalError("Failed to initialize ARSession")
            }

            let renderThread = Thread {
                self.renderLoop()
            }
            renderThread.name = "Render Thread"
            renderThread.start()
        }
    }

    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices

        let vd = MTLVertexDescriptor()

        vd.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        vd.attributes[VertexAttribute.position.rawValue].offset = 0
        vd.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue

        vd.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        vd.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        vd.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue

        vd.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        vd.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        vd.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex

        vd.layouts[BufferIndex.meshGenerics.rawValue].stride = 8
        vd.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        vd.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex

        return vd
    }

    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             layerRenderer: LayerRenderer,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object

        let library = device.makeDefaultLibrary()

        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")

        let pd = MTLRenderPipelineDescriptor()
        pd.label = "RenderPipeline"
        pd.vertexFunction = vertexFunction
        pd.fragmentFunction = fragmentFunction
        pd.vertexDescriptor = mtlVertexDescriptor
        pd.colorAttachments[0].pixelFormat = layerRenderer.configuration.colorFormat
        pd.depthAttachmentPixelFormat = layerRenderer.configuration.depthFormat
        pd.maxVertexAmplificationCount = layerRenderer.properties.viewCount

        return try device.makeRenderPipelineState(descriptor: pd)
    }

    class func buildMesh(device: MTLDevice,
                         mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
        /// Create and condition mesh data to feed into a pipeline using the given vertex descriptor

        let metalAllocator = MTKMeshBufferAllocator(device: device)

        let mdlMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(4, 4, 4),
                                     segments: SIMD3<UInt32>(2, 2, 2),
                                     geometryType: MDLGeometryType.triangles,
                                     inwardNormals:false,
                                     allocator: metalAllocator)

        let mdlVD = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)

        guard let attributes = mdlVD.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate

        mdlMesh.vertexDescriptor = mdlVD

        return try MTKMesh(mesh:mdlMesh, device:device)
    }

    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling

        let textureLoader = MTKTextureLoader(device: device)

        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]

        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }

    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering

        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:UniformsArray.self, capacity:1)
    }

    private func updateGameState(drawable: LayerRenderer.Drawable,
                                 deviceAnchor: DeviceAnchor?) {

        /// Update any game state before rendering

        let rotationAxis = SIMD3<Float>(1, 1, 0)
        let modelRotationMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        let modelTranslationMatrix = matrix4x4_translation(0.0, 0.0, -8.0)
        let modelMatrix = modelTranslationMatrix * modelRotationMatrix

        let simdDeviceAnchor = deviceAnchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        func uniforms(forViewIndex viewIndex: Int) -> Uniforms {

            let view = drawable.views[viewIndex]
            let viewMatrix = (simdDeviceAnchor * view.transform).inverse
            let projection = ProjectiveTransform3D(leftTangent: Double(view.tangents[0]),
                                                   rightTangent: Double(view.tangents[1]),
                                                   topTangent: Double(view.tangents[2]),
                                                   bottomTangent: Double(view.tangents[3]),
                                                   nearZ: Double(drawable.depthRange.y),
                                                   farZ: Double(drawable.depthRange.x),
                                                   reverseZ: true)

            return Uniforms(projectionMatrix: .init(projection), modelViewMatrix: viewMatrix * modelMatrix)
        }

        self.uniforms[0].uniforms.0 = uniforms(forViewIndex: 0)
        if drawable.views.count > 1 {
            self.uniforms[0].uniforms.1 = uniforms(forViewIndex: 1)
        }

        rotation += 0.01
    }

    func renderFrame() {
        /// Per frame updates hare

        guard let frame = layerRenderer.queryNextFrame() else { return }

        frame.startUpdate()
        // Perform frame independent work
        frame.endUpdate()

        guard let timing = frame.predictTiming() else { return }
        LayerRenderer.Clock().wait(until: timing.optimalInputTime)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Failed to create command buffer")
        }

        guard let drawable = frame.queryDrawable() else { return }

        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

        frame.startSubmission()

        let time = LayerRenderer.Clock.Instant.epoch.duration(to: drawable.frameTiming.presentationTime).timeInterval
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: time)

        drawable.deviceAnchor = deviceAnchor

        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
            semaphore.signal()
        }

        self.updateDynamicBufferState()

        self.updateGameState(drawable: drawable, deviceAnchor: deviceAnchor)

        let rd = MTLRenderPassDescriptor()
        rd.colorAttachments[0].texture = drawable.colorTextures[0]
        rd.colorAttachments[0].loadAction = .clear
        rd.colorAttachments[0].storeAction = .store
        rd.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        rd.depthAttachment.texture = drawable.depthTextures[0]
        rd.depthAttachment.loadAction = .clear
        rd.depthAttachment.storeAction = .store
        rd.depthAttachment.clearDepth = 0.0
        rd.rasterizationRateMap = drawable.rasterizationRateMaps.first
        if layerRenderer.configuration.layout == .layered {
            rd.renderTargetArrayLength = drawable.views.count
        }

        /// Final pass rendering code here
        guard let re = commandBuffer.makeRenderCommandEncoder(descriptor: rd) else {
            fatalError("Failed to create render encoder")
        }

        re.label = "Primary Render Encoder"
        re.pushDebugGroup("Draw Box")
        re.setCullMode(.back)
        re.setFrontFacing(.counterClockwise)
        re.setRenderPipelineState(pipelineState)
        re.setDepthStencilState(depthState)
        re.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)

        let viewports = drawable.views.map { $0.textureMap.viewport }

        re.setViewports(viewports)

        if drawable.views.count > 1 {
            var viewMappings = (0..<drawable.views.count).map {
                MTLVertexAmplificationViewMapping(
                    viewportArrayIndexOffset: UInt32($0),
                    renderTargetArrayIndexOffset: UInt32($0))
            }
            re.setVertexAmplificationCount(viewports.count, viewMappings: &viewMappings)
        }

        for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else {
                return
            }

            if layout.stride != 0 {
                let buffer = mesh.vertexBuffers[index]
                re.setVertexBuffer(buffer.buffer, offset:buffer.offset, index: index)
            }
        }

        re.setFragmentTexture(colorMap, index: TextureIndex.color.rawValue)

        for submesh in mesh.submeshes {
            re.drawIndexedPrimitives(
                type: submesh.primitiveType,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer,
                indexBufferOffset: submesh.indexBuffer.offset)
        }
        re.popDebugGroup()
        re.endEncoding()

        drawable.encodePresent(commandBuffer: commandBuffer)
        commandBuffer.commit()

        frame.endSubmission()
    }

    func renderLoop() {
        while true {
            if layerRenderer.state == .invalidated {
                print("Layer is invalidated")
                return
            } else if layerRenderer.state == .paused {
                layerRenderer.waitUntilRunning()
                continue
            } else {
                autoreleasepool {
                    self.renderFrame()
                }
            }
        }
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

#endif
