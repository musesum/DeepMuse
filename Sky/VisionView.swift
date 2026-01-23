import SwiftUI
import RealityKit
import MuVision
import MetalKit
import MuMenu
import MuHands
import MuFlo 

#if os(visionOS)

struct VisionView: View {
    
    @Environment(ImmersionModel.self) var immersionModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase
    
    let visionModel: VisionModel
    let skyModel: SkyModel
    var immersed: Bool { immersionModel.state != .windowed }

    init(_ visionModel: VisionModel) {
        self.visionModel = visionModel
        self.skyModel = visionModel.skyModel
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
            SkyVisionView(skyModel)
                .frame(minWidth  : immersed ? 640 : 800,
                       maxWidth  : immersed ? 800 : 1920,
                       minHeight : immersed ? 480 : 600,
                       maxHeight : immersed ? 480 : 1280)

            Picker("Immersion", selection: Binding<ImmersionModel.State>(
                get: { immersionModel.state },
                set: { immersionModel.state = $0 })) {
                Image(systemName: "rectangle")
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .tag(ImmersionModel.State.windowed)
                Image("icon.room.white")

                    .frame(width: 44, height: 44)
                    .tag(ImmersionModel.State.mixed)
                Image("icon.galaxy.white")
                    
                    .frame(width: 44, height: 44)
                    .tag(ImmersionModel.State.full)
            }

            .pickerStyle(.segmented)
            .frame(width: 148, height: 44)
            .offset(x: 0, y: -20)
            .padding(16)
        }
        .onAppear {
            skyModel.setImmersion(immersionModel.state != .windowed)
            Task {
                if let handsTracker = visionModel.handsTracker {
                    await handsTracker.startHands()
                }
            }
        }
        .opacity(showOpacity)
        .animation(showAnimation, value: showOpacity)
        .onChange(of: handsPhase.update) { changeHandsPhase(handsPhase) }
        .onChange(of: immersionModel.state) { _, newValue in
            // Ensure style follows the tab locally (SkyApp also sets this)
            immersionModel.style = (newValue == .full) ? .full : .mixed
        }
    }
}
#endif
