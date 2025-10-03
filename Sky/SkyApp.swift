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

    @Environment(\.dismissImmersiveSpace) var dismissImmersive
    @Environment(\.openImmersiveSpace) var openImmersive
    @State public var immersionModel: ImmersionModel

    let nextFrame: NextFrame
    let visionModel: VisionModel
    let skyModel: SkyModel

    init() {
        self.immersionModel = ImmersionModel()
        self.visionModel = VisionModel()
        self.skyModel = visionModel.skyModel
        self.nextFrame = skyModel.nextFrame
    }

    var body: some Scene {

        WindowGroup(id: "SkyApp") {
            VisionView(visionModel)
                .environment(immersionModel)
                .onOpenURL { url in visionModel.openURL(url) }
                .onChange(of: immersionModel.state) { _, state in
                    DebugLog { P("🎬 SkyApp.onChange tab: \(state)") }
                    Task { @MainActor in
                        switch state {
                        case .windowed:
                            await dismissImmersive()
                            immersionModel.isImmersed = false
                        case .mixed, .full:
                            if immersionModel.isImmersed == false {
                                let result = await openImmersive(id: ImmersiveScene.id)
                                immersionModel.changed(result)
                            }
                        }
                    }
                    skyModel.setImmersion(state != .windowed)
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        ImmersiveScene(visionModel)
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

