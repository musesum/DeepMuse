// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo
import MuMenu
import MuHands

#if os(visionOS)
import CompositorServices

@main
struct SkyApp: App {

    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase
    @State public var immersionModel: ImmersionModel

    let nextFrame: NextFrame
    let appModel: VisionModel
    let skyCanvas: SkyCanvas
    let visionView: VisionView

    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat {  immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }

    init() {
        self.immersionModel = ImmersionModel()
        self.appModel = VisionModel()
        self.skyCanvas = appModel.skyCanvas
        self.nextFrame = skyCanvas.nextFrame
        self.handsPhase = skyCanvas.handsPhase
        self.visionView = VisionView(appModel)
    }

    var body: some Scene {

        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        WindowGroup(id: "SkyApp") {
            visionView
                .environment(immersionModel)
                .environmentObject(handsPhase)
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
         .onChange(of: handsPhase.state) { _, state in
             var icon: String = "🤏"
             switch state.left  {
             case .begin : icon += "🔰" ; showTime.showNow()
             case .end   : icon += "♦️" ; showTime.startAutoFade()
             default     : icon += "⬜︎"
             }
             switch state.right  {
             case .begin : icon += "🔰" ; showTime.showNow()
             case .end   : icon += "♦️" ; showTime.startAutoFade()
             default     : icon += "⬜︎"
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
    let skyCanvas: SkyCanvas

    init() {
        self.appModel = AppModel()
        self.skyCanvas = appModel.skyCanvas
    }

    var body: some Scene {
        WindowGroup {
            skyCanvas.skyView
                .onOpenURL { url in
                    skyCanvas.readUserArchive(url, skyCanvas.nextFrame, local: false)
                }
        }
    }
}
#endif

