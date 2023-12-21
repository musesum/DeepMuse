import MetalKit
import ModelIO


let allocator = MTKMeshBufferAllocator(device: device)
let vertexBuffer = allocator.newBuffer(with: vertices, type: .vertex)

let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.stride)
let indexBuffer = allocator.newBuffer(with: indexData, type: .index)

let submesh = MDLSubmesh(indexBuffer: indexBuffer,
                         indexCount: indices.count,
                         indexType: .uint32,
                         geometryType: .triangles,
                         material: nil) // You can create a default MDLMaterial if needed

mdlMesh = MDLMesh(vertexBuffers: [vertexBuffer],
                   vertexCount: vertices.count,
                   descriptor:  metalVD.modelVD,
                   submeshes: [submesh])

// The mesh is now ready with a default submesh
