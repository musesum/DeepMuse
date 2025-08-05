// created by musesum on 9/14/23.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation

struct SkyView: View {

    @Environment(\.scenePhase) var scenePhase
    #if os(visionOS)
    @Environment(ImmersionModel.self) var immersionModel
    #endif

    let id = Visitor.nextId()
    let menuVms: [MenuVm]
    let skyVm: SkyVm
    let cornerVms: [CornerVm]
    let touchView: TouchViewRepresentable!
    let nextFrame: NextFrame
    let glassState: GlassState
    let panicState: PanicState

    public init(_ skyVm: SkyVm) {

        self.skyVm = skyVm
        self.nextFrame = skyVm.nextFrame
        self.menuVms = skyVm.menuHands.menuVms
        self.cornerVms = menuVms.map { $0.rootVm.cornerVm }
        self.touchView = TouchViewRepresentable(menuVms, skyVm.touchView)
        self.glassState = GlassState(skyVm.root˚)
        self.panicState = PanicState(skyVm.root˚, nextFrame)
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyVm)
    }

    func changedGeoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        DebugLog { P("🎬 SkyView changed geometry ") }
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        skyVm.setFrame(frame, insets, onAppear: onAppear)
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
            case .active     : msg += "🟩 .active id: \(id)"
            case .inactive   : msg += "🟥 .inactive"
            case .background : msg += "🟦 .background"
            @unknown default : break
            }
            P(msg)
        }
        if changed {
            switch phase {
            case .active: nextFrame.pause = false
            case .inactive: skyVm.saveArchive("Snapshot", "autosaved") { nextFrame.pause = true }
            default:  break
            }
        }
    }
    var showTouchView: Bool {
        #if os(visionOS)
        let goImmersive = immersionModel.goImmersive
        let isImmersive = immersionModel.isImmersive
        NoDebugLog { P("🎬 SkyView go/is Immersive: \(goImmersive)/\(isImmersive) id: \(id)") }
        return !goImmersive
        #else
        return true
        #endif
    }

    var body: some View {
        
        GeometryReader { geo in
            Group {
                if showTouchView {
                    touchView
                        .cornerRadius(40)
                        .frame(width: touchWidth(geo), height: touchHeight(geo))
                        .offset(touchOffset(geo))
                }
                MenuView(menuVms)
                    .environmentObject(glassState)
                    .background(.clear)
                #if os(iOS)
                    .persistentSystemOverlays(.hidden)
                #elseif os(visionOS)
                    .persistentSystemOverlays(immersionModel.isImmersive ? .hidden : .visible)
                #endif
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

