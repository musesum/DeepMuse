// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu

struct MenuTouchView: View {
    @Environment(\.scenePhase) var scenePhase

    var menuVms: [MenuVm]
    let skyCanvas = SkyCanvas.shared
    var renderState: RenderState = .passthrough
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    let touchView: TouchViewRepresentable!

    public init() {

        self.menuVms = MenuVms(Flo.root˚).menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyCanvas.touchesView)
        RenderDepth.state = renderState
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        
        GeometryReader { geo in
            touchView
                .frame(width:  (geo.size.width  +
                                geo.safeAreaInsets.leading +
                                geo.safeAreaInsets.trailing),
                       height: (geo.size.height +
                                geo.safeAreaInsets.top +
                                geo.safeAreaInsets.bottom))
                .offset(CGSize(width:  -geo.safeAreaInsets.leading,
                               height: -geo.safeAreaInsets.top))
            MenuView(menuVms, skyCanvas)
                .background(.clear)
                .persistentSystemOverlays(.hidden)
            
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                DebugLog { P("🎬 MenuTouchView 🟢") }
                NextFrame.shared.pause = false
            case .inactive:
                DebugLog { P("🎬 MenuTouchView 🔴") }
                SkyCanvas.shared.saveArchive("Snapshot", "autosaved") {
                    NextFrame.shared.pause = true
                }
            default:  break
            }
        }

    }
}
