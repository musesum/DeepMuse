// SkyApp.swift
// created by musesum on 9/14/23.

import SwiftUI
import MuVision
import MuFlo 
import MuPeer

#if os(visionOS)
import CompositorServices

@main
struct SkyApp: App {

    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State public var immersionModel = ImmersionModel()
    let visionModel = VisionModel(.windowed)

    var body: some Scene {

        @Environment(\.scenePhase) var scenePhase
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

        WindowGroup(id: "App") {
            VisionView(visionModel)
                .environment(immersionModel)
                .onOpenURL { url in
                    visionModel.openURL(url)
                }
                .onChange(of: immersionModel.showImmersiveSpace) { _, newValue in
                    // Manage the lifecycle of the immersive space.
                    Task { @MainActor in
                        if newValue {
                            let act = await openImmersiveSpace(id: ImmersiveScene.id)
                            immersionModel.changed(act)
                        } else if immersionModel.immersiveSpaceIsShown {
                            await dismissImmersiveSpace()
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        ImmersiveScene(visionModel)
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
    let root˚: Flo
    let skyCanvas: SkyCanvas
    let nextFrame = NextFrame()
    let archiveVm: ArchiveVm
    let peers = Peers("Sky")
    init() {
        root˚ = Flo("√")
        archiveVm = ArchiveVm(nextFrame)
        skyCanvas = SkyCanvas(root˚, .windowed, archiveVm, peers, UIScreen.main.scale, UIScreen.main.bounds)
    }
    var body: some Scene {
        @Environment(\.scenePhase) var scenePhase
        WindowGroup {
            SkyView(skyCanvas, peers)
                .onOpenURL { url in
                    skyCanvas.readUserArchive(url, skyCanvas.nextFrame, local: false)
                }
        }
    }
}
#endif

