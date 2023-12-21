//  Created by musesum on 8/4/23.

import MetalKit
import Spatial

class MeshTexEllipse: MeshTexture {

    var radius = CGFloat(1)
    var inward = false

    init(_ device: MTLDevice,
         texName : String,
         compare : MTLCompareFunction,
         radius  : CGFloat,
         inward  : Bool,
         winding : MTLWinding) throws {

        try super.init(device  : device,
                       texName : texName,
                       compare : compare,
                       winding : winding)

        self.radius = radius
        self.inward = inward

        guard let modelMesh = modelEllipsoid(device) else {
            throw RendererError.badVertex
        }
        mtkMesh = try MTKMesh(mesh: modelMesh, device: device)

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
        attributes[Vertexi.texcoord].name = MDLVertexAttributeTextureCoordinate
        attributes[Vertexi.normal  ].name = MDLVertexAttributeNormal


        modelMesh.vertexDescriptor = modelVD
        return modelMesh
    }

}
