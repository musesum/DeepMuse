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
    let skyVm: SkyVm
    let visionView: VisionView

    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat {  immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }

    init() {
        self.immersionModel = ImmersionModel()
        self.appModel = VisionModel()
        self.skyVm = appModel.skyVm
        self.nextFrame = skyVm.nextFrame
        self.handsPhase = skyVm.handsPhase
        self.visionView = VisionView(appModel)
    }

    func changeHandsPhase(_ handsPhase: HandsPhase) {
        let state = handsPhase.state
        if let phase = state.left {
            switch phase {
            case .end : showTime.startAutoFade()
            default   : showTime.showNow()
            }
        }
        if let phase = state.right {
            switch phase  {
            case .end : showTime.startAutoFade()
            default   : showTime.showNow()
            }
        }
        NoTimeLog(handsPhase.icon, interval: 1) { P(handsPhase.icon) }
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
                    skyVm.setImmersion(goImmersive)
                }
                .opacity(showOpacity)
                .animation(showAnimation, value: showOpacity)
        }
        .onChange(of: handsPhase.update) { changeHandsPhase(handsPhase) }
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
    let skyVm: SkyVm

    init() {
        self.appModel = AppModel()
        self.skyVm = appModel.skyVm
    }

    var body: some Scene {
        WindowGroup {
            SkyView(skyVm)
                .onOpenURL { url in
                    skyVm.readUserArchive(url, skyVm.nextFrame, local: false)
                }
        }
    }
}
#endif


