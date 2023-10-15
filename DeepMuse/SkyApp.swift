//
//  SkyApp.swift
//  DeepMuse
//
//  Created by warren on 9/14/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//
import UIKit
import SwiftUI
import MuMenu

#if os(xrOS)
import CompositorServices

@main
struct SkyApp: App {
    @State private var immersionStyle: ImmersionStyle = .full
    var body: some Scene {
        WindowGroup {
            MenuSkyView.shared
            ContentView()
        }
        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                _ = SkyRenderer(layerRenderer)
            }
        }.immersionStyle(selection: $immersionStyle, in: .full)
    }
}
struct ContentStageConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {

        configuration.depthFormat = .depth32Float
        configuration.colorFormat = .bgra8Unorm_srgb

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
