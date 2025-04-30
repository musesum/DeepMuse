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

    private let visionModel: VisionModel

    init(_ visionModel: VisionModel) {
        self.visionModel = visionModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            visionModel.skyView
                .frame(minWidth: immersionModel.showImmersiveSpace ? 640 : 800,
                       minHeight: immersionModel.showImmersiveSpace ? 480 : 600)
                .frame(maxWidth: immersionModel.showImmersiveSpace ? 800 : 1920,
                       maxHeight: immersionModel.showImmersiveSpace ? 480 : 1280)
            Button {
                immersionModel.showImmersiveSpace.toggle()
            } label: {
                Text(immersionModel.showImmersiveSpace ? "Passthrough" : "Immersive")
            }
            .padding(6)
        }
        .onAppear {
            visionModel.setImmersion(immersionModel.showImmersiveSpace)
            Task { await visionModel.startHands() }
        }
        .onChange(of: immersionModel.showImmersiveSpace) { _, newValue in
            visionModel.setImmersion(newValue)
        }
        .opacity(immersionModel.showMenu ? 1 : 0)
    }
}
#endif
