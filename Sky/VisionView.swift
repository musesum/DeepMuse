import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu

#if os(visionOS)

struct VisionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppModel.self) var appModel
    let skyCanvas: SkyCanvas
    private var visionModel: VisionModel
    init(_ visionModel: VisionModel,
         _ skyCanvas: SkyCanvas) {
        self.visionModel = visionModel
        self.skyCanvas = skyCanvas
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            visionModel.menuTouchView
                .frame(minWidth: appModel.showImmersiveSpace ? 640 : 800,
                       minHeight: appModel.showImmersiveSpace ? 480 : 600)
                .frame(maxWidth: appModel.showImmersiveSpace ? 800 : 1920,
                       maxHeight: appModel.showImmersiveSpace ? 480 : 1280)
            Button {
                appModel.showImmersiveSpace.toggle()
            } label: {
                Text(appModel.showImmersiveSpace ? "Passthrough" : "Immersive")
            }
            .padding(6)
        }
        .onAppear {
            visionModel.setImmersion(appModel.showImmersiveSpace)
            Task { await visionModel.startHands() }
        }
        .onChange(of: appModel.showImmersiveSpace) { _, newValue in
            visionModel.setImmersion(newValue)
        }
        .opacity(visionModel.showMenu ? 1 : 0)
    }
}
#endif
