// created by musesum
#if os(visionOS)
import Spatial
import CompositorServices
import MuMetal

/// triple buffered Uniform for either 1 or 2 eyes
class UniformEyeBuf<Item> {
    //typealias UniEyes = UniformEyes
    public struct UniEyes {
        // a uniform for each eye
        var eye: (Item, Item)
    }

    let uniformSize: Int
    let tripleUniformSize: Int
    let uniformBuf: MTLBuffer
    let infinitelyFar: Bool // infinit distance for stars (same background for both eyes)

    var uniformEyes: UnsafeMutablePointer<UniEyes>
    var tripleOffset = 0
    var tripleIndex = 0

    init(_ device: MTLDevice,
         _ label: String,
         far: Bool) {

        // round up to multiple of 256 bytes
        self.uniformSize = (MemoryLayout<UniEyes>.size + 0xFF) & -0x100
        self.tripleUniformSize = uniformSize * TripleBufferCount
        self.infinitelyFar = far
        self.uniformBuf = device.makeBuffer(length: tripleUniformSize, options: [.storageModeShared])!
        self.uniformBuf.label = label

        uniformEyes = UnsafeMutableRawPointer(uniformBuf.contents())
            .bindMemory(to: UniEyes.self, capacity: 1)
    }

    /// Update projection and rotation
    func updateEyeUniforms(_ layerDrawable: LayerRenderer.Drawable,
                           _ modelMatrix: simd_float4x4) {

        let anchor = layerDrawable.deviceAnchor
        updateTripleBufferedUniform()

        let deviceAnchor = anchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        self.uniformEyes[0].eye.0 = uniformForEyeIndex(0)
        if layerDrawable.views.count > 1 {
            self.uniformEyes[0].eye.1 = uniformForEyeIndex(1)
        }

        func updateTripleBufferedUniform() {

            tripleIndex = (tripleIndex + 1) % TripleBufferCount
            tripleOffset = uniformSize * tripleIndex
            let uniformPtr = uniformBuf.contents() + tripleOffset
            uniformEyes = UnsafeMutableRawPointer(uniformPtr)
                .bindMemory(to: UniEyes.self, capacity: 1)
        }

        func uniformForEyeIndex(_ index: Int) -> Item {

            let view = layerDrawable.views[index]

            let viewMatrix = (deviceAnchor * view.transform).inverse

            let projection = ProjectiveTransform3D(
                leftTangent   : Double(view.tangents[0]),
                rightTangent  : Double(view.tangents[1]),
                topTangent    : Double(view.tangents[2]),
                bottomTangent : Double(view.tangents[3]),
                nearZ         : Double(layerDrawable.depthRange.y),
                farZ          : Double(layerDrawable.depthRange.x),
                reverseZ      : true)

            var viewModel = viewMatrix * modelMatrix

            if infinitelyFar {
                viewModel.columns.3 = simd_make_float4(0.0, 0.0, 0.0, 1.0)
            }
            let eyeUniforms = UniformEye(.init(projection), viewModel)
            return eyeUniforms as! Item
        }
    }
    func setViewMappings(_ renderCmd     : MTLRenderCommandEncoder,
                         _ layerDrawable : LayerRenderer.Drawable,
                         _ viewports     : [MTLViewport]) {

        if layerDrawable.views.count > 1 {
            var viewMappings = (0 ..< layerDrawable.views.count).map {
                MTLVertexAmplificationViewMapping(
                    viewportArrayIndexOffset: UInt32($0),
                    renderTargetArrayIndexOffset: UInt32($0))
            }
            renderCmd.setVertexAmplificationCount(
                viewports.count,
                viewMappings: &viewMappings)
        }
    }
    func setUniformBuf(_ renderCmd: MTLRenderCommandEncoder)  {

        renderCmd.setVertexBuffer(uniformBuf,
                                  offset: tripleOffset,
                                  index: VertexIndex.uniforms /* 3 */)
    }

}
#endif
