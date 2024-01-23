//  SkyApp.swift
//  created by musesum on 9/14/23.

import UIKit
import SwiftUI
import MuMenu
import MuMetal
import MuFlo // NextFrame

#if os(visionOS)
import MuVision
import CompositorServices

@main
struct SkyApp: App {

    @State private var immersionStyle: ImmersionStyle = .full

    var body: some Scene {

        WindowGroup(id: "App") {
            ContentView()
        }.windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer { layerRenderer in
                _ = RenderSky(layerRenderer)
            }
        }
        .body.upperLimbVisibility(.visible)
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}

struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {

        configuration.depthFormat = .depth32Float
        configuration.colorFormat = MetalRenderPixelFormat

        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)

        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}

#else

@main
struct app: App {
    var body: some Scene {
        WindowGroup {
            MenuSkyView.shared
        }
    }
}

#endif
