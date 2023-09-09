

import SwiftUI
import MuMenu
#if os(xrOS)
import CompositorServices

struct ContentStageConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = .bgra8Unorm_srgb

        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)

        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}

@main
struct MetalRendererApp: App {
    var body: some Scene {
        WindowGroup {
            //MenuView() 
        }.windowStyle(.volumetric)
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                let renderer = Renderer(layerRenderer)
                renderer.startRenderLoop()
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
#endif
