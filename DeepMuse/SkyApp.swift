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
struct app: App {
    var body: some Scene {
        WindowGroup {
            MenuSkyView.shared
        }
        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: MetalLayerConfiguration()) { layerRenderer in
                let renderer = RenderSky(layerRenderer)
                renderer.startRenderLoop()
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}

struct MetalLayerConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration)
    {
        let supportsFoveation = capabilities.supportsFoveation
        configuration.layout = .dedicated
        configuration.isFoveationEnabled = supportsFoveation
        configuration.colorFormat = .rgba16Float
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
