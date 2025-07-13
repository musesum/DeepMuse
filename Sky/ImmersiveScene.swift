// created by musesum on 4/4/25

#if os(visionOS)

import SwiftUI
import MuFlo // PrintLog
import MuVision 
import CompositorServices

struct ImmersiveScene: Scene {

    @Environment(ImmersionModel.self) var immersionModel
    static let id = "Immersive"

    let pipeline: SkyPipeline
    let nextFrame: NextFrame

    init(_ appModel: AppModel) {
        let skyCanvas = appModel.skyCanvas
        self.pipeline = skyCanvas.pipeline
        self.nextFrame = skyCanvas.nextFrame
    }
    var body: some Scene {
        ImmersiveSpace(id: Self.id) {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                layerRenderer in
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                nonisolated(unsafe) let renderer = Renderer(layerRenderer, pipeline, nextFrame)
                Task(priority: .high) {
                    try await renderer.renderLoop()
                }
            }
        }
        .immersionStyle(selection: .constant(immersionModel.immersionStyle), in: .mixed, .full)
        .upperLimbVisibility(.visible)
    }
}
struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        DebugLog{ P("🧭 Immmersive makeConfiguration") }
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
