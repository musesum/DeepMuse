// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo
import MuMenu

#if os(visionOS)
import CompositorServices

@MainActor
class ShowApp: ObservableObject, @unchecked Sendable {
    @Published var showTime = ShowTime()
}

@main
struct SkyApp: App {

    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @ObservedObject var showApp = ShowApp()
    @ObservedObject var handState: HandState
    @State public var immersionModel: ImmersionModel

    let nextFrame: NextFrame
    let appModel: VisionModel
    let skyCanvas: SkyCanvas
    let visionView: VisionView

    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat {  immersed ? showApp.showTime.opacity : 1 }
    var showAnimation: Animation { showApp.showTime.animation }

    init() {
        self.immersionModel = ImmersionModel()
        self.appModel = VisionModel()
        self.skyCanvas = appModel.skyCanvas
        self.handState = HandState(skyCanvas.root˚)
        self.nextFrame = skyCanvas.nextFrame
        self.visionView = VisionView(appModel)
    }

    var body: some Scene {

        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        WindowGroup(id: "SkyApp") {

            visionView
                .environment(immersionModel)
                .environmentObject(handState)
                .onOpenURL { url in appModel.openURL(url) }
                .onChange(of: immersionModel.goImmersive) { _, goImmersive in
                    DebugLog { P("🎬 SkyApp.onChange goImmersive: \(goImmersive)") }
                    Task { @MainActor in
                        if goImmersive {
                            if immersionModel.isImmersive == false {
                                let result = await openImmersiveSpace(id: ImmersiveScene.SceneId)
                                immersionModel.changed(result)
                            }
                        } else  {
                            await dismissImmersiveSpace()
                            immersionModel.isImmersive = false
                        }
                    }
                    skyCanvas.setImmersion(goImmersive)
                }
                .opacity(showOpacity)
                .animation(showAnimation, value: showOpacity)
        }
         .onChange(of: handState.showPhase) { _, showPhase in
             var icon: String = "🤏"
             switch showPhase {
             case 0: icon += "🤏🔰" ; showApp.showTime.showNow()
             case 3: icon += "🤏♦️" ; showApp.showTime.startAutoFade()
             default: return
             }
        }
        .windowStyle(.plain)
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
        WindowGroup {
            appModel.skyCanvas.skyView
                .onOpenURL { url in
                    skyCanvas.readUserArchive(url, skyCanvas.nextFrame, local: false)
                }
        }
    }
}
#endif

