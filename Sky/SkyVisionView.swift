// created by musesum on 9/17/25
#if os(visionOS)
import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation

struct SkyVisionView: View {

    @Environment(\.scenePhase) var scenePhase
    @Environment(ImmersionModel.self) var immersion

    let id = Visitor.nextId()
    let visionModel: VisionModel
    let cornerVms: [CornerVm]
    let touchView: TouchViewRepresentable!
    let panicState: PanicState

    public init(_ visionModel: VisionModel) {

        self.visionModel = visionModel
        let menuVms = visionModel.menus.menuVms
        self.cornerVms = menuVms.map { $0.rootVm.cornerVm }
        self.touchView = TouchViewRepresentable(menuVms, visionModel.touchView)
        self.panicState = PanicState(visionModel.root˚)
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, visionModel)
    }

    func changedGeoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        DebugLog { P("🎬 SkyView changed geometry ") }
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        visionModel.setFrame(frame, insets, onAppear: onAppear)
    }
    func touchWidth(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width +
        geo.safeAreaInsets.leading +
        geo.safeAreaInsets.trailing
    }
    func touchHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.height +
        geo.safeAreaInsets.top +
        geo.safeAreaInsets.bottom
    }
    func touchOffset(_ geo: GeometryProxy) -> CGSize {
        CGSize(width:  -geo.safeAreaInsets.leading,
               height: -geo.safeAreaInsets.top)
    }

    func changedScene(_ phase: ScenePhase, changed: Bool) {

        DebugLog {
            var msg = "🎬 SkyView scenePhase: "
            switch phase {
            case .active     : msg += "🟢 .active id: \(id)"
            case .inactive   : msg += "🔴 .inactive"
            case .background : msg += "🔵 .background"
            @unknown default : break
            }
            P(msg)
        }
        if changed {
            switch phase {
            case .active: NextFrame.shared.pause = false
            case .inactive: visionModel.saveArchive("Snapshot", "autosaved") { NextFrame.shared.pause = true }
            default:  break
            }
        }
    }

    var body: some View {

        GeometryReader { geo in
            Group {
                // activity indicator during startup
                if scenePhase != .active {
                    ZStack {
                        Image("icon.ring")
                            .scaleEffect(0.33)
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    if immersion.state == .windowed {
                        touchView
                            .cornerRadius(40)
                            .frame(width: touchWidth(geo), height: touchHeight(geo))
                            .offset(touchOffset(geo))
                    }
                    visionModel.menuView
                        .background(.clear)
                        .persistentSystemOverlays(immersion.isImmersed ? .hidden : .visible)
                }
            }
            .onAppear() {
                changedScene(scenePhase, changed: false)
                changedGeoFrame(geo, onAppear: true)
            }
            .onChange(of: scenePhase) { changedScene($1, changed: true) }
            .onChange(of: geo.frame(in: .global)) { changedGeoFrame(geo, onAppear: false) }
        }
    }
}
#endif
