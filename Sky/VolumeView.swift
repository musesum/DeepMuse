#if os(visionOS)
import RealityKit
import SwiftUI
import MuFlo
import MuVision

@MainActor
public struct VolumeView: View {

    final class ViewModel: ObservableObject {
        @Published var drawQueue: [TextureResource.DrawableQueue] = []
        @Published var faceTex: [TextureResource] = []
    }

    let pipeline: Pipeline
    var _cubeNode: CubeNode?
    var cubeNode: CubeNode? {
        guard let _cubeNode = _cubeNode ?? pipeline.node["cube"] as? CubeNode else { return nil }
        return _cubeNode
    }

    @StateObject private var viewModel = ViewModel()

    public init(_ pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    private func makeBox() async -> Entity {
        let materials = await makeMaterials(viewModel, side: 512)
        let edge: Float = 0.25
        let mesh = MeshResource.generateBox(width  : edge,
                                            height : edge,
                                            depth  : edge,
                                            splitFaces: true)
        return ModelEntity(mesh: mesh, materials: materials)
    }

    public var body: some View {
        RealityView { content in
            let box = await makeBox()
            content.add(box)
            ManipulationComponent.configureEntity(box)
        } update: { _ in
            if viewModel.drawQueue.count == 6 {
                cubeNode?.boxFaces(to: viewModel.drawQueue)
            }
        }
        .realityViewLayoutBehavior(.centered)
        //.preferredWindowClippingMargins(.all, 400)
    }
}
#endif
