// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo // NextFrame

#if os(visionOS)
import CompositorServices

@main
struct SkyApp: App {

    @State private var immersionStyle: ImmersionStyle = .full
    let root˚: Flo
    let skyCanvas: SkyCanvas
    init() {
        root˚ = Flo("√")
        skyCanvas = SSkyCanvas(root˚, 3, .zero)
    }

    var body: some Scene {
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        WindowGroup(id: "App") {
            VisionView(skyCanvas)
                .onOpenURL { url in
                    Task {
                        await SkyCanvas.shared.readUserArchive(url, local: false)
                    }
                }
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                _ = RenderLayer($0, SkyCanvas.shared.pipeline)
            }
        }
        .body.upperLimbVisibility(.visible)
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}

struct ContentStageConfiguration: CompositorLayerConfiguration {

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        DebugLog{ P("🧭 Immersive config") }
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
struct SkyApp: App {
    let root˚: Flo
    let skyCanvas: SkyCanvas
    init() {
        root˚ = Flo("√")
        skyCanvas = SkyCanvas(root˚, UIScreen.main.scale, UIScreen.main.bounds)
    }
    var body: some Scene {
        @Environment(\.scenePhase) var scenePhase
        WindowGroup {
            MenuTouchView(skyCanvas)
                .onOpenURL { url in
                    Task {
                        await skyCanvas.readUserArchive(url, local: false)
                    }
                }
        }
    }
}
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}
