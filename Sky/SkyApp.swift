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

    let visionModel: VisionModel

    init() {
        self.immersionModel = ImmersionModel()
        self.visionModel = VisionModel()
    }

    var body: some Scene {

        WindowGroup(id: "SkyApp") {
            VisionView(visionModel)
                .environment(immersionModel)
                .onOpenURL { url in
                    visionModel.readUserArchive(url, local: false) }
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
                    visionModel.setImmersion(state != .windowed)
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

    let skyModel: SkyModel

    init() {
        self.skyModel = SkyModel.shared
    }

    var body: some Scene {
        WindowGroup {
            SkyView()
                .onOpenURL { url in
                    SkyModel.shared.readUserArchive(url, local: false)
                }
                .onAppear {
                    NextFrame.shared.pause = false
                }
        }
    }
}
#endif

