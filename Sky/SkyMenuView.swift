// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuMenu
import MuVision
import MuMenu

struct SkyMenuView: View {

    public static let shared = SkyMenuView()
    
    let root: Flo
    var menuVms: [MenuVm]
    var menuView: MenuView
    var skyCanvas: SkyCanvas
    var renderState: RenderState = .metal
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }

    public init() {

        self.skyCanvas = SkyCanvas.shared
        self.root = skyCanvas.archive.root˚
        self.menuVms = MenuVms(root).menuVms
        self.menuView = MenuView(menuVms, skyCanvas)
        RenderDepth.state = renderState
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {

        GeometryReader { geo in
                TouchViewRepresentable(cornerVms, skyCanvas.skyTouchView)
                    .frame(width:  geo.size.width  + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                           height: geo.size.height + geo.safeAreaInsets.top     + geo.safeAreaInsets.bottom)
                    .offset(CGSize(width: -geo.safeAreaInsets.leading, height:  -geo.safeAreaInsets.top))

                menuView
                    .background(.clear)
                    .persistentSystemOverlays(.hidden)
        }
    }
}

