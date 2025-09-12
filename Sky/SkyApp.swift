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
    let id = Visitor.nextId()
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @State public var immersionModel: ImmersionModel

    let nextFrame: NextFrame
    let appModel: VisionModel
    let skyModel: SkyModel

    init() {
        self.immersionModel = ImmersionModel()
        self.appModel = VisionModel()
        self.skyModel = appModel.skyModel
        self.nextFrame = skyModel.nextFrame
    }

    var body: some Scene {

        WindowGroup(id: "SkyApp") {
            VisionView(appModel)
                .environment(immersionModel)
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
                    skyModel.setImmersion(goImmersive)
                }
                .accessibilityHidden(true)
                .accessibilityRespondsToUserInteraction(false)
                .persistentSystemOverlays(immersionModel.isImmersive
                                          ? .hidden : .visible)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.5, depth: 0.5, in: .meters)
        .windowResizability(.contentSize)

        ImmersiveScene(appModel)
            .environment(immersionModel)
    }
    var body_: some Scene {
        ImmersiveSpace {
            CompositorLayer(configuration: ContentStageConfiguration()) {
                layerRenderer in
                DebugLog{ P("🧭 Immmersive CompositorLayer") }
                let renderer = Renderer(layerRenderer, skyModel.pipeline, nextFrame)
                Task(priority: .high) {
                    try await renderer.renderLoop(id)
                }
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)
        .upperLimbVisibility(.visible)
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
    let id = Visitor.nextId()
    let appModel: AppModel
    let skyModel: SkyModel
    let touchView: TouchViewRepresentable!

    init() {
        self.appModel = AppModel()
        self.skyModel = appModel.skyModel
        let menuVms = skyModel.menus.menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyModel.touchView)
    }

    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in

                touchView
                    .cornerRadius(40)
                    .frame(width: Menu.touchWidth(geo),
                           height: Menu.touchHeight(geo))
                    .offset(Menu.touchOffset(geo))

                    .onOpenURL { url in
                        skyModel.readUserArchive(url, skyModel.nextFrame, local: false)
                    }
                    .persistentSystemOverlays(.hidden)
                SkyView(skyModel) 
            }
        }
    }
}
#endif
