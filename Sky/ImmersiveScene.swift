// created by musesum on 4/4/25

#if os(visionOS)

import SwiftUI
import MuFlo // PrintLog
import MuMenu
import MuVision
import CompositorServices
import RealityKit

struct ImmersiveScene: SwiftUI.Scene {
    static let id = "ImmersiveScene"
    @Environment(ImmersionModel.self) var immersionModel

    let pipeline: SkyPipeline
    let menuView: MenuView

    init(_ skyModel: SkyModel) {
        let skyModel = skyModel
        self.pipeline = skyModel.pipeline
        self.menuView = skyModel.menuView
    }

    var body: some SwiftUI.Scene {
        ImmersiveSpace(id: Self.id) {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                layerRenderer in
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                let renderer = Renderer(layerRenderer, pipeline)
                Task(priority: .high) { try await renderer.renderLoop() }
            }
        }
        .immersionStyle(selection: Binding(get: { immersionModel.style },
                                           set: { immersionModel.style = $0 }),
                        in: .mixed, .full)
        .upperLimbVisibility(.visible)
    }
}
struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        NoDebugLog{ P("🧭 Immmersive makeConfiguration") }
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = MuRenderPixelFormat

        let hasFoveation = capabilities.supportsFoveation
        configuration.isFoveationEnabled = hasFoveation

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = hasFoveation ? [.foveationEnabled] : []
        let layouts = capabilities.supportedLayouts(options: options)

        configuration.layout = layouts.contains(.layered) ? .layered : .dedicated
    }
}

#endif


