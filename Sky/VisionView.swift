import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuHands

#if os(visionOS)

struct VisionView: View {
    
    @Environment(ImmersionModel.self) var immersion
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase
    
    let appModel: VisionModel
    let skyModel: SkyModel
    let nextFrame: NextFrame
    var immersed: Bool { immersion.goImmersive }
    
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
        let title = "VisionView " + handsPhase.handsState
        TimeLog(title, interval: 1) { P(title) }
    }
    
    var showOpacity: CGFloat { immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SkyView(skyModel)
                .frame(minWidth  : immersed ? 640 : 800,
                       maxWidth  : immersed ? 800 : 1920,
                       minHeight : immersed ? 480 : 600,
                       maxHeight : immersed ? 480 : 1280)
            
            Button {
                immersion.goImmersive.toggle()
            } label: {
                Image(immersion.goImmersive
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
            skyModel.setImmersion(immersion.goImmersive)
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
