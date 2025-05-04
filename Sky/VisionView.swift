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

    let appModel: VisionModel

    init(_ appModel: VisionModel) {
        self.appModel = appModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            appModel.skyView
                .frame(minWidth  : immersionModel.goImmersive ? 640 : 800,
                       minHeight : immersionModel.goImmersive ? 480 : 600)
                .frame(maxWidth  : immersionModel.goImmersive ? 800 : 1920,
                       maxHeight : immersionModel.goImmersive ? 480 : 1280)
            Button {
                immersionModel.goImmersive.toggle()
            } label: {
                Text(immersionModel.goImmersive ? "Passthrough" : "Immersive")
            }
            .padding(6)
        }
        .onAppear {
            appModel.setImmersion(immersionModel.goImmersive)
            Task { await appModel.handsTracker.startHands() }
        }
        .onChange(of: immersionModel.goImmersive) { _, newValue in
            appModel.setImmersion(newValue)
        }
        .opacity(immersionModel.showMenu ? 1 : 0)
    }
}
#endif
