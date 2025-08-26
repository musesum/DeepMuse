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
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase

    let appModel: VisionModel
    let skyModel: SkyModel
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
        self.skyModel = appModel.skyModel
        self.nextFrame = skyModel.nextFrame
        self.handsPhase = skyModel.handsPhase
        PrintLog("🎬 VisionView")
    }

    func changeHandsPhase(_ handsPhase: HandsPhase) {
        let state = handsPhase.state
        if let phase = state.left {
            switch phase {
            case .ended : showTime.startAutoFade()
            default     : showTime.showNow()
            }
        }
        if let phase = state.right {
            switch phase  {
            case .ended : showTime.startAutoFade()
            default     : showTime.showNow()
            }
        }
        let title = "VisionView "+handsPhase.handsState
        TimeLog(title, interval: 1) { P(title) }
    }
    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat {  immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SkyView(skyModel)
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
            skyModel.setImmersion(immersionModel.goImmersive)
            Task {
                if let handsTracker = appModel.handsTracker {
                    await handsTracker.startHands()
                }
            }
        }
        .opacity(showOpacity)
        .animation(showAnimation, value: showOpacity)
        .onChange(of: handsPhase.update) { changeHandsPhase(handsPhase) }
    }
}
#endif
