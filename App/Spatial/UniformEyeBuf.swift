// created by musesum.
#if os(visionOS)
import Spatial
import CompositorServices

let TripleBufferCount = 3  // uniforms for 3 adjacent frames

/// triple buffered Uniform for either 1 or 2 eyes
class UniformEyeBuf {

    let uniformSize: Int
    let tripleUniformSize: Int
    let uniformBuf: MTLBuffer
    let infinitelyFar: Bool // infinit distance for stars (same background for both eyes)

    var uniformEyes: UnsafeMutablePointer<UniformEyes>
    var tripleOffset = 0
    var tripleIndex = 0

    init(_ device: MTLDevice,
         _ label: String,
         infinitelyFar: Bool) {

        // round up to multiple of 256 bytes
        self.uniformSize = (MemoryLayout<UniformEyes>.size + 0xFF) & -0x100
        self.tripleUniformSize = uniformSize * TripleBufferCount
        self.infinitelyFar = infinitelyFar
        self.uniformBuf = device.makeBuffer(length: tripleUniformSize,
                                            options: [.storageModeShared])!
        self.uniformBuf.label = label

        uniformEyes = UnsafeMutableRawPointer(uniformBuf.contents())
            .bindMemory(to: UniformEyes.self, capacity: 1)
    }

    /// Update projection and rotation
    func updateUniforms(_ drawable: LayerRenderer.Drawable,
                        _ rotationMat: simd_float4x4) {

        let anchor = drawable.deviceAnchor
        updateTripleBufferedUniform()

        let translateMat = translateQuat(x: 0.0, y: 0.0, z: -8.0)
        let modelMatrix = translateMat * rotationMat
        let deviceAnchor = anchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        self.uniformEyes[0].eye.0 = uniformForEyeIndex(0)
        if drawable.views.count > 1 {
            self.uniformEyes[0].eye.1 = uniformForEyeIndex(1)
        }
        func updateTripleBufferedUniform() {

            tripleIndex = (tripleIndex + 1) % TripleBufferCount
            tripleOffset = uniformSize * tripleIndex
            let uniformPtr = uniformBuf.contents() + tripleOffset
            uniformEyes = UnsafeMutableRawPointer(uniformPtr)
                .bindMemory(to: UniformEyes.self, capacity: 1)
        }

        func uniformForEyeIndex(_ index: Int) -> Uniforms {

            let view = drawable.views[index]

            let viewMatrix = (deviceAnchor * view.transform).inverse
            
            let projection = ProjectiveTransform3D(
                leftTangent   : Double(view.tangents[0]),
                rightTangent  : Double(view.tangents[1]),
                topTangent    : Double(view.tangents[2]),
                bottomTangent : Double(view.tangents[3]),
                nearZ         : Double(drawable.depthRange.y),
                farZ          : Double(drawable.depthRange.x),
                reverseZ      : true)

            var viewModel = viewMatrix * modelMatrix
            if infinitelyFar {
                viewModel.columns.3 = simd_make_float4(0.0, 0.0, 0.0, 1.0)
            }
            return Uniforms(projection: .init(projection),
                            viewModel: viewModel)
        }
    }
    func setMappings(_ drawable: LayerRenderer.Drawable,
                     _ viewports: [MTLViewport],
                     _ renderCommand: MTLRenderCommandEncoder) {

        if drawable.views.count > 1 {
            var viewMappings = (0 ..< drawable.views.count).map {
                MTLVertexAmplificationViewMapping(
                    viewportArrayIndexOffset: UInt32($0),
                    renderTargetArrayIndexOffset: UInt32($0))
            }
            renderCommand.setVertexAmplificationCount(
                viewports.count,
                viewMappings: &viewMappings)
        }
        renderCommand.setVertexBuffer(uniformBuf,
                                      offset: tripleOffset,
                                      index: Vertexi.uniforms)
    }

}
#endif
