// created by musesum on 4/4/25

#if os(visionOS)

import SwiftUI
import MuFlo // PrintLog
import MuVision 
import CompositorServices

struct ImmersiveScene: Scene {

    @Environment(AppModel.self) var appModel
    static let id = "Immersive"

    let skyPipeline: SkyPipeline
    init(_ skyPipeline: SkyPipeline) {
        self.skyPipeline = skyPipeline
    }
    var body: some Scene {
        ImmersiveSpace(id: Self.id) {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                layerRenderer in
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                Task(priority: .high) {
                    let renderer = Renderer(layerRenderer, skyPipeline, appModel)
                    try await renderer.renderLoop()
                }
            }
        }
        .immersionStyle(selection: .constant(appModel.immersionStyle), in: .mixed, .full)
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
