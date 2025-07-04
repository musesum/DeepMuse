// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo

#if os(visionOS)
import CompositorServices

@main
struct SkyApp: App {

    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State public var immersionModel = ImmersionModel()
    let appModel = VisionModel()

    var body: some Scene {

        @Environment(\.scenePhase) var scenePhase
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

        WindowGroup(id: "App") {
            VisionView(appModel)
                .environment(immersionModel)
                .onOpenURL { url in
                    appModel.openURL(url)
                }
                .onChange(of: immersionModel.goImmersive) { _, newValue in
                    // Manage the lifecycle of the immersive space.
                    Task { @MainActor in
                        if newValue {
                            let act = await openImmersiveSpace(id: ImmersiveScene.id)
                            immersionModel.changed(act)
                        } else if immersionModel.isImmersive {
                            await dismissImmersiveSpace()
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        ImmersiveScene(appModel)
            .environment(immersionModel)
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
    let appModel: AppModel
    var skyCanvas: SkyCanvas { appModel.skyCanvas }

    init() {
        self.appModel = AppModel()
    }

    var body: some Scene {
        @Environment(\.scenePhase) var scenePhase
        WindowGroup {
            appModel.skyView
                .onOpenURL { url in
                    skyCanvas.readUserArchive(url, skyCanvas.nextFrame, local: false)
                }
        }
    }
}
#endif

