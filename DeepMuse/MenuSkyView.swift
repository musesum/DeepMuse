// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuMenu

struct MenuSkyView: View {

    public static let shared = MenuSkyView()
    var menuView: MenuView
    var skyCanvas: SkyCanvas
    var hostingC: HostingController!
    var hostView: UIView!

    public init() {
        skyCanvas = SkyCanvas.shared

        menuView = MenuView(skyCanvas.archive.root˚,
                            skyCanvas.touchView, 
                            skyCanvas)

        hostingC = HostingController(rootView: self)
        hostView = hostingC.view
        hostView.isOpaque = false //????
        hostView.backgroundColor = .clear
        hostView.layer.backgroundColor = nil
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        VStack {
            menuView
                .background(.clear)

        }
    }
}

