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
            SkyVisionView(handsTracker: SkyCanvas.shared.handsTracker)
        }.windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) { renderer in
                _ = SkyRender(renderer)
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

        let hasFoveation = capabilities.supportsFoveation
        configuration.isFoveationEnabled = hasFoveation

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = hasFoveation ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)

        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}

#else

@main
struct app: App {
    var body: some Scene {
        WindowGroup {
            SkyMenuView.shared
        }
    }
}

#endif
