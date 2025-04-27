// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu

#if os(visionOS)

@MainActor
final class VisionModel: ObservableObject, ImmersionDelegate {
    let menuTouchView: MenuTouchView
    let skyCanvas: SkyCanvas
    let touchCanvas: TouchCanvas
    let handsModel: HandsModel
    let handsTracker: HandsTracker
    var immersive: Bool = false
    var showMenu: Bool = true


    init(_ skyCanvas: SkyCanvas) {
        self.skyCanvas = skyCanvas
        self.touchCanvas = TouchCanvas(skyCanvas.touchDraw)
        self.menuTouchView = MenuTouchView(skyCanvas)

        handsModel = HandsModel(touchCanvas, skyCanvas.root˚)
        handsTracker = HandsTracker(handsModel.handsFlo)
        touchCanvas.immersiveDelegate = self
    }
    
    func setImmersion(_ immersive: Bool) {
        self.immersive = immersive
        touchCanvas.immersive = immersive
        NextFrame.shared.pause = immersive
        skyCanvas.pipeline.layer.opacity = immersive ? 0 : 1
        RenderDepth.state = immersive ? .immersive : .passthrough
    }

    /// only change if different -- not implemented
    func updateImmersion(_ immersive: Bool) async {
        if self.immersive != immersive {
            setImmersion(immersive)
        }
    }
    /// reshow menu -- not implemented 
    func reshowMenu() async {
        DebugLog{ P("👐👆 reshowMenu showMenu: \(self.showMenu) ") }
        if !showMenu {
            showMenu = true
            objectWillChange.send()
        }
    }

    func startHands() async {
        await handsTracker.startHands()
        await handsTracker.updateHands()
        await handsTracker.monitorSessionEvents()
    }
}
#endif
