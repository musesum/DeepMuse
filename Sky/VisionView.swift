import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu

#if os(visionOS)

struct VisionView: View {

    @State private var showImmersion = false
    @State public var immersive = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.scenePhase) var scenePhase

    var menuTouchView = MenuTouchView()
    var handsModel: HandsModel
    var handsTracker: HandsTracker
    var skyCanvas: TouchCanvas

    init(_ skyCanvas: SkyCanvas) {
        self.skyCanvas = skyCanvas
        self.handsModel = HandsModel(TouchCanvas.shared, Root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }

    func setImmersion(_ immersive: Bool) {
        self.immersive = immersive
        NextFrame.shared.pause = immersive
        menuTouchView.skyCanvas.pipeline.layer.opacity = immersive ? 0 : 1
        RenderDepth.state = immersive ? .immersive : .passthrough
    }

    var body: some View {

        ZStack(alignment: .bottom) {

            if immersive {
                menuTouchView
                    .frame(minWidth: 640, minHeight: 480)
                    .frame(maxWidth: 800, maxHeight: 480)

            } else {
                menuTouchView
                    .frame(minWidth: 800, minHeight: 600)
                    .frame(maxWidth: 1920, maxHeight: 1280)
            }
            Toggle(showImmersion
                   ? "Passthrough"
                   : "Immersive",
                   isOn: $showImmersion)
            .toggleStyle(.button)
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            .glassBackgroundEffect()

            .onChange(of: showImmersion) { _, newValue in
                Task {
                    if newValue {
                        switch await openImmersiveSpace(id: "ImmersiveSpace") {
                        case .opened: setImmersion(true)
                        default:      setImmersion(false)
                        }
                    } else if immersive {
                        await dismissImmersiveSpace()
                        setImmersion(false)
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    DebugLog { P("🎬 SkyVisionView") }
                    NextFrame.shared.pause = false
                case .inactive:
                    DebugLog { P("🏁 SkyVisionView") }
                    SkyCanvas.shared.saveArchive("Snapshot", "autosaved") {
                        NextFrame.shared.pause = true
                    }
                default:  break
                }
            }
            .task { await handsTracker.startHands() }
            .task { await handsTracker.updateHands() }
            .task { await handsTracker.monitorSessionEvents() }
        }
    }
}

#endif
