import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuHands

#if os(visionOS)

struct VisionView: View {

    @Environment(ImmersionModel.self) var immersionModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase

    let appModel: VisionModel
    let skyVm: SkyVm
    let nextFrame: NextFrame

    func logScenePhase(_ phase: ScenePhase, changed: Bool) {
        var msg = "🎬 VisionView scenePhase: "
        switch phase {
        case .active     : msg += "🟩 .active"
        case .inactive   : msg += "🟥 .inactive"
        case .background : msg += "🟦 .background"
        @unknown default : break
        }
        DebugLog { P(msg) }

    }
    init(_ appModel: VisionModel) {
        self.appModel = appModel
        self.skyVm = appModel.skyVm
        self.nextFrame = skyVm.nextFrame
        PrintLog("🎬 VisionView")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SkyView(skyVm)
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
            logScenePhase(scenePhase, changed: false)
            skyVm.setImmersion(immersionModel.goImmersive)
            Task {
                if let handsTracker = appModel.handsTracker {
                    await handsTracker.startHands()
                }
                //await appModel.handsTracker.startHands()
            }
        }
        //.onChange(of: scenePhase) { logScenePhase($1, changed: true) }
    }
}
#endif

