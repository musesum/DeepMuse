// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuMenu
import MuVision

struct SkyMenuView: View {

    public static let shared = SkyMenuView()
    
    var menuView: MenuView
    var skyCanvas: SkyCanvas
    var renderState: RenderState = .metal

    public init() {

        RenderDepth.state = renderState
        
        skyCanvas = SkyCanvas.shared

        menuView = MenuView(skyCanvas.archive.root˚,
                            skyCanvas.touchView, 
                            skyCanvas)

        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {

        menuView
            .background(.clear)
            .persistentSystemOverlays(.hidden)
    }
}

