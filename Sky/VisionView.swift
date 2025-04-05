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
    
    @StateObject private var visionModel = VisionModel()
    
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
        
        .onChange(of: appModel.showImmersiveSpace) { _, newValue in
            visionModel.setImmersion(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task { @MainActor in
                if newPhase == .background {
                    DebugLog { P("🎬 VisionView scenePhase .background") }
                    appModel.showImmersiveSpace = false
                } else {
                    DebugLog { P("🎬 VisionView scenePhase NOT .background") }
                }
            }
        }
        .onAppear {
            Task {
                await visionModel.start(appModel.showImmersiveSpace)
            }
        }
    }
}

@MainActor
final class VisionModel: ObservableObject {
    let menuTouchView = MenuTouchView()
    let skyCanvas = SkyCanvas.shared
    let handsModel: HandsModel
    let handsTracker: HandsTracker
    
    init() {
        handsModel = HandsModel(TouchCanvas.shared, Flo.root˚)
        handsTracker = HandsTracker(handsModel.handsFlo)
    }

    func setImmersion(_ immersive: Bool) {
        NextFrame.shared.pause = immersive
        skyCanvas.pipeline.layer.opacity = immersive ? 0 : 1
        RenderDepth.state = immersive ? .immersive : .passthrough
    }
    
    func start(_ showImmersiveSpace: Bool) async {
        setImmersion(showImmersiveSpace)
        await handsTracker.startHands()
        await handsTracker.updateHands()
        await handsTracker.monitorSessionEvents()

    }
}

#endif
