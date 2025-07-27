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
    var menuVms: [MenuVm]
    let skyCanvas: SkyCanvas
    let peers: Peers
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    let touchView: TouchViewRepresentable!
    let nextFrame: NextFrame
    var glassState: GlassState

    public init(_ skyCanvas: SkyCanvas,
                _ peers: Peers) {

        self.skyCanvas = skyCanvas
        self.nextFrame = skyCanvas.nextFrame
        self.peers = peers
        self.menuVms = skyCanvas.menuHands.menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyCanvas.touchView)
        self.glassState = GlassState(skyCanvas.root˚)
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    func geoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        skyCanvas.setFrame(frame, insets, onAppear: onAppear)
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

    func logScenePhase(_ phase: ScenePhase, changed: Bool) {
        var msg = "🎬 SkyView scenePhase: "
        switch phase {
        case .active     : msg += "🟩 .active id: \(id)"
        case .inactive   : msg += "🟥 .inactive"
        case .background : msg += "🟦 .background"
        @unknown default : break
        }
        DebugLog { P(msg) }
        if changed {
            switch phase {
            case .active: nextFrame.pause = false
            case .inactive: skyCanvas.saveArchive("Snapshot", "autosaved") { nextFrame.pause = true }
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
                logScenePhase(scenePhase, changed: false)
                geoFrame(geo, onAppear: true)
            }
            .onChange(of: scenePhase) { logScenePhase($1, changed: true) }
            .onChange(of: geo.frame(in: .global)) { geoFrame(geo, onAppear: false) }
        }


    }
}

