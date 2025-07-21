import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu

#if os(visionOS)

struct VisionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ImmersionModel.self) var immersionModel
    @ObservedObject var menuState: MenuState

    let appModel: VisionModel
    let skyCanvas: SkyCanvas
    let nextFrame: NextFrame

    init(_ appModel: VisionModel) {
        self.appModel = appModel
        self.skyCanvas = appModel.skyCanvas
        self.menuState = MenuState(skyCanvas.root˚)
        self.nextFrame = skyCanvas.nextFrame
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            appModel.skyCanvas.skyView
                .environmentObject(menuState)
                .frame(minWidth  : immersionModel.goImmersive ? 640 : 800,
                       minHeight : immersionModel.goImmersive ? 480 : 600)
                .frame(maxWidth  : immersionModel.goImmersive ? 800 : 1920,
                       maxHeight : immersionModel.goImmersive ? 480 : 1280)
            Button {
                immersionModel.goImmersive.toggle()
            } label: {
                Image(immersionModel.goImmersive
                      ? "icon.room.white"
                      : "icon.galaxy.white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)

            }
            .offset(x: 0, y: -20)
            .padding(6)
        }
        .onAppear {
            immersionModel.skyViewAppeared()
            appModel.setImmersion(immersionModel.goImmersive)
            Task { await appModel.handsTracker.startHands() }
        }
        .onChange(of: immersionModel.goImmersive) { _, newValue in
            appModel.setImmersion(newValue)
        }
        .onChange(of: menuState.showMenu) {
            if menuState.showMenu,
               !immersionModel.isSkyViewVisible {
                immersionModel.isSkyViewVisible = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                DebugLog { P("🎬 MenuTouchView 🟢 .active") }
                nextFrame.pause = false
                immersionModel.skyViewAppeared()
            case .inactive:
                DebugLog { P("🎬 MenuTouchView 🔴 .inactive") }
                skyCanvas.saveArchive("Snapshot", "autosaved") {
                    nextFrame.pause = true
                }
            case .background:
                DebugLog { P("🎬 MenuTouchView 🔵 .background") }
                menuState.showMenu = false
                immersionModel.isSkyViewVisible = false
            @unknown default:
                break
            }
        }
    }
}
#endif

