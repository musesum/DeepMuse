// created by musesum on 4/4/25

#if os(visionOS)

import SwiftUI
import MuFlo // PrintLog
import MuVision 
import CompositorServices

struct ImmersiveScene: Scene {

    @Environment(AppModel.self) var appModel

    static let id = "Immersive"

    var body: some Scene {
        ImmersiveSpace(id: Self.id) {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                let renderer = RenderLayer($0, SkyCanvas.shared.pipeline)
                renderer.startRenderLoop()
            }
        }
        .upperLimbVisibility(.visible)
        .immersionStyle(selection: .constant(appModel.immersionStyle), in: .mixed, .full)
    }
}
struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        DebugLog{ P("🧭 Immmersive config") }
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
