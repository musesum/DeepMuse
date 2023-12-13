//  Created by musesum on 8/4/23.

import MetalKit
import Spatial

class MeshTexture {

    var texName: String
    var texture: MTLTexture
    var metalVD: MTLVertexDescriptor
    var mesh: MTKMesh?
    var stencil: MTLDepthStencilState?
    var device: MTLDevice

    init(device  : MTLDevice,
         texName : String,
         compare : MTLCompareFunction) throws {

        self.device = device
        self.texName = texName
        texture = loadTexture(device, texName)
        metalVD = MTLVertexDescriptor()

        let sd = MTLDepthStencilDescriptor()
        sd.isDepthWriteEnabled = true
        sd.depthCompareFunction = compare
        stencil = device.makeDepthStencilState(descriptor: sd)
    }
    func addVertexFormat(_ format: MTLVertexFormat,
                         _ index: Int) {
        let stride: Int
        switch format {
        case .float2: stride = MemoryLayout<Float>.size * 2
        case .float3: stride = MemoryLayout<Float>.size * 3
        default: return
        }
        metalVD.attributes[index].format = format
        metalVD.attributes[index].offset = 0
        metalVD.attributes[index].bufferIndex = index
        metalVD.layouts[index].stride = stride
        metalVD.layouts[index].stepRate = 1
        metalVD.layouts[index].stepFunction = .perVertex
    }

    func drawMesh(_ renderCmd: MTLRenderCommandEncoder,
                  _ renderPipe: MTLRenderPipelineState,
                  _ winding: MTLWinding) {

        guard let stencil else { return err("\(texName) stencil") }
        guard let mesh    else { return err("\(texName) mesh") }

        renderCmd.setCullMode(.back)
        renderCmd.setRenderPipelineState(renderPipe)
        renderCmd.setFrontFacing(winding)
        renderCmd.setDepthStencilState(stencil)

        for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else { return }

            if layout.stride != 0 {
                let vb = mesh.vertexBuffers[index]
                renderCmd.setVertexBuffer(vb.buffer, offset: vb.offset, index: index)
            }
        }
        renderCmd.setFragmentTexture(texture, index: Texturei.colori)

        for submesh in mesh.submeshes {
            renderCmd.drawIndexedPrimitives(
                type              : submesh.primitiveType,
                indexCount        : submesh.indexCount,
                indexType         : submesh.indexType,
                indexBuffer       : submesh.indexBuffer.buffer,
                indexBufferOffset : submesh.indexBuffer.offset)
        }
        func err(_ msg: String) {
            print("⁉️ \(texName) Mesh::draw error : \(msg)")
        }
    }
}

class MeshEllipsoid: MeshTexture {

    var radius = CGFloat(1)
    var inward = false

    init(_ device  : MTLDevice,
         _ texName : String,
         _ compare : MTLCompareFunction,
         radius    : CGFloat,
         inward    : Bool) throws {

        try super.init(device  : device,
                       texName : texName,
                       compare : compare)

        self.radius = radius
        self.inward = inward
        makeMetalVD()
        guard let modelMesh = modelEllipsoid(device) else {
            throw RendererError.badVertex
        }
        mesh = try MTKMesh(mesh: modelMesh, device: device)

        func err(_ msg: String) {
            print("⁉️ \(texName) Mesh::draw error : \(msg)")
        }
    }

    func modelEllipsoid(_ device: MTLDevice) -> MDLMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        let radii = SIMD3<Float>(repeating: Float(radius))
        let modelMesh = MDLMesh.newEllipsoid(
            withRadii        : radii,
            radialSegments   : 24,
            verticalSegments : 24,
            geometryType     : .triangles,
            inwardNormals    : inward,
            hemisphere       : false,
            allocator        : allocator)

        let modelVD = MTKModelIOVertexDescriptorFromMetal(metalVD)
        guard let attributes = modelVD.attributes as? [MDLVertexAttribute] else {
            return nil
        }
        attributes[Vertexi.position].name = MDLVertexAttributePosition
        attributes[Vertexi.normal  ].name = MDLVertexAttributeNormal
        attributes[Vertexi.texcoord].name = MDLVertexAttributeTextureCoordinate

        modelMesh.vertexDescriptor = modelVD
        return modelMesh
    }
    func makeMetalVD() {

        metalVD = MTLVertexDescriptor()
        addVertexFormat(.float3, Vertexi.position)
        addVertexFormat(.float2, Vertexi.normal  )
        addVertexFormat(.float3, Vertexi.texcoord)
    }
}
