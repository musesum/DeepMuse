// created by musesum on 4/4/25

#if os(visionOS)

import SwiftUI
import MuFlo // PrintLog
import MuVision 
import CompositorServices

struct ImmersiveScene: Scene {
    static let SceneId = "Immersive"
    let id = Visitor.nextId()
    @Environment(ImmersionModel.self) var immersionModel

    let pipeline: SkyPipeline
    let nextFrame: NextFrame
    let appModel: AppModel

    init(_ appModel: AppModel) {
        self.appModel = appModel
        let skyVm = appModel.skyVm
        self.pipeline = skyVm.pipeline
        self.nextFrame = skyVm.nextFrame
    }
    var body: some Scene {
        ImmersiveSpace(id: Self.SceneId) {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                layerRenderer in
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                let renderer = Renderer(layerRenderer, pipeline, nextFrame)
                Task(priority: .high) {
                    try await renderer.renderLoop(id)
                }
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)
        .upperLimbVisibility(.visible)
    }
}
struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        NoDebugLog{ P("🧭 Immmersive makeConfiguration") }
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = MetalRenderPixelFormat

        let hasFoveation = capabilities.supportsFoveation
        configuration.isFoveationEnabled = hasFoveation

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = hasFoveation ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)

        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}

#endif
