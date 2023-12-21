// created by musesum on 12/21/23

import simd
import ModelIO
import MetalKit

extension MTLVertexDescriptor {
    var modelVD: MDLVertexDescriptor {
        let mdlDescriptor = MDLVertexDescriptor()

        // Map the attribute indices to names
        let attributeNames = [
            MDLVertexAttributePosition,
            MDLVertexAttributeNormal,
            MDLVertexAttributeTextureCoordinate,
            // Add more mappings as needed
        ]
        for (index, name) in attributeNames.enumerated() {
            if let mtlAttribute = self.attributes[index], mtlAttribute.format != .invalid {
                let mdlAttribute = MDLVertexAttribute(
                    name: name,
                    format: MDLVertexFormat(rawValue: mtlAttribute.format.rawValue)!,
                    offset: mtlAttribute.offset,
                    bufferIndex: mtlAttribute.bufferIndex)
                mdlDescriptor.attributes[index] = mdlAttribute
            }
        }
        // Metal typically supports up to 4 vertex buffer layouts
        for i in 0..<4 {
            if let mtlLayout = self.layouts[i],
                mtlLayout.stride != 0 {
                let mdlLayout = MDLVertexBufferLayout(stride: mtlLayout.stride)
                mdlDescriptor.layouts[i] = mdlLayout
            }
        }
        return mdlDescriptor
    }
}
