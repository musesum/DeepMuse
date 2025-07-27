import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuHands

#if os(visionOS)

struct VisionView: View {

    let id = Visitor.nextId() //.....
    @Environment(ImmersionModel.self) var immersionModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase

    let appModel: VisionModel
    let skyCanvas: SkyCanvas
    let skyView: SkyView?
    let nextFrame: NextFrame

    func logScenePhase(_ phase: ScenePhase, changed: Bool) {
        var msg = "🎬 VisionView scenePhase: "
        switch phase {
        case .active     : msg += "🟩 .active id: \(id)"
        case .inactive   : msg += "🟥 .inactive"
        case .background : msg += "🟦 .background"
        @unknown default : break
        }
        DebugLog { P(msg) }

    }
    init(_ appModel: VisionModel) {
        self.appModel = appModel
        self.skyCanvas = appModel.skyCanvas
        self.skyView  = appModel.skyCanvas.skyView
        self.nextFrame = skyCanvas.nextFrame
        PrintLog("🎬 VisionView id: \(self.id)")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            skyView
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
            skyCanvas.setImmersion(immersionModel.goImmersive)
            Task { await appModel.handsTracker.startHands() }
        }
        //.onChange(of: scenePhase) { logScenePhase($1, changed: true) }
    }
}
#endif

