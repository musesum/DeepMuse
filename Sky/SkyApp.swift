// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo // NextFrame

#if os(visionOS)
import CompositorServices

@main
struct SkyApp: App {

    @State public var appModel = AppModel()
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    var body: some Scene {

        @Environment(\.scenePhase) var scenePhase
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        let visionModel = VisionModel()

        WindowGroup(id: "App") {
            VisionView(visionModel)
                .environment(appModel)
                .onOpenURL { url in
                    SkyCanvas.shared.readUserArchive(url, local: false)
                }
                .onChange(of: appModel.showImmersiveSpace) { _, newValue in
                    // Manage the lifecycle of the immersive space.
                    Task { @MainActor in
                        if newValue {
                            switch await openImmersiveSpace(id: ImmersiveScene.id) {
                            case .opened:
                                appModel.immersiveSpaceIsShown = true
                            case .userCancelled:
                                // stay in immersive state to allow user to use
                                // only hand pose to controll parameters 
                                // otherwise fallthrough to @nknown default to stop
                                DebugLog{ P("👐👆 setting visionModel.showMenu to false") }
                                visionModel.showMenu = false
                                break
                            case .error:
                                fallthrough
                            @unknown default:
                                appModel.immersiveSpaceIsShown = false
                                appModel.showImmersiveSpace = false
                            }
                        } else if appModel.immersiveSpaceIsShown {
                            await dismissImmersiveSpace()
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        ImmersiveScene()
            .environment(appModel)
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}

#else

@main
struct SkyApp: App {
    var body: some Scene {
        @Environment(\.scenePhase) var scenePhase
        WindowGroup {
            MenuTouchView()
                .onOpenURL { url in
                    SkyCanvas.shared.readUserArchive(url, local: false)
                }
        }
    }
}
#endif

