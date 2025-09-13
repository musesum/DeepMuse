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
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        ImmersiveScene(appModel)
            .environment(immersionModel)
    }
}

#else

@main
struct SkyApp: App {
    let appModel: AppModel
    let skyModel: SkyModel

    init() {
        self.appModel = AppModel()
        self.skyModel = appModel.skyModel
    }

    var body: some Scene {
        WindowGroup {
            SkyView(skyModel)
                .onOpenURL { url in
                    skyModel.readUserArchive(url, skyModel.nextFrame, local: false)
                }
        }
    }
}
#endif
