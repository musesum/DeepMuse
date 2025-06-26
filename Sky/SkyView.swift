// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers

struct SkyView: View {

    @Environment(\.scenePhase) var scenePhase

    var menuVms: [MenuVm]
    let skyCanvas: SkyCanvas
    let nextFrame: NextFrame
    let peers: Peers
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    let touchView: TouchViewRepresentable!
    var viewing: Viewing

    public init(_ skyCanvas: SkyCanvas,
                _ viewing: Viewing,
                _ peers: Peers) {
        self.skyCanvas = skyCanvas
        self.viewing = viewing
        self.nextFrame = skyCanvas.nextFrame
        self.peers = peers
        self.menuVms = MenuVms(skyCanvas.root˚, skyCanvas.archiveVm, peers).menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyCanvas.touchView)
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        
        GeometryReader { geo in
            if viewing.canvas {
                touchView
                    .frame(width:  (geo.size.width  +
                                    geo.safeAreaInsets.leading +
                                    geo.safeAreaInsets.trailing),
                           height: (geo.size.height +
                                    geo.safeAreaInsets.top +
                                    geo.safeAreaInsets.bottom))
                    .offset(CGSize(width:  -geo.safeAreaInsets.leading,
                                   height: -geo.safeAreaInsets.top))
            }
            if viewing.menu {
                MenuView(menuVms, skyCanvas)
                    .background(.clear)
                    .persistentSystemOverlays(.hidden)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                DebugLog { P("🎬 MenuTouchView 🟢") }
                nextFrame.pause = false
            case .inactive:
                DebugLog { P("🎬 MenuTouchView 🔴") }
                skyCanvas.saveArchive("Snapshot", "autosaved") {
                    nextFrame.pause = true
                }
            default:  break
            }
        }
    }
}
