// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu

struct SkyMenuTouchView: View {
    @Environment(\.scenePhase) var scenePhase
    public static let shared = SkyMenuTouchView()

    let root˚ = Flo.root˚
    var menuVms: [MenuVm]
    var menuView: MenuView
    var skyCanvas: SkyCanvas
    var renderState: RenderState = .passthrough
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }

    public init() {

        self.skyCanvas = SkyCanvas.shared
        self.menuVms = MenuVms(root˚).menuVms
        self.menuView = MenuView(menuVms, skyCanvas)
        RenderDepth.state = renderState
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        
        GeometryReader { geo in
            TouchViewRepresentable(cornerVms, skyCanvas.touchesView)
                .frame(width:  (geo.size.width  +
                                geo.safeAreaInsets.leading +
                                geo.safeAreaInsets.trailing),
                       height: (geo.size.height +
                                geo.safeAreaInsets.top +
                                geo.safeAreaInsets.bottom))
                .offset(CGSize(width:  -geo.safeAreaInsets.leading,
                               height: -geo.safeAreaInsets.top))
            menuView
                .background(.clear)
                .persistentSystemOverlays(.hidden)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                DebugLog { P("🎬 SkyMenuTouchView") }
                NextFrame.shared.pause = false
            case .inactive:
                DebugLog { P("🏁 SkyMenuTouchView") }
                SkyCanvas.shared.saveArchive("Snapshot", "autosaved") {
                    NextFrame.shared.pause = true
                }
            default:  break
            }
        }

    }
}
