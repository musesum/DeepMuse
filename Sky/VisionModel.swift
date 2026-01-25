// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // TapeFlo
import MuVision
import MetalKit
import MuMenu
import MuPeers
import MuHands


#if os(visionOS)

class VisionModel: SkyModel {

    var handsModel: HandsModel!
    var handsTracker: HandsTracker!
   
    override init () {
        super.init()
        self.handsModel = HandsModel(touchCanvas, root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }
    
    override func setFrame(_ frame: CGRect,
                           _ insets: EdgeInsets,
                           onAppear: Bool) {

        self.insets = insets + 40

        var size: CGSize
        switch renderState {
        case .immersed:
            if pipeline.viewports.count > 0,
               let v = pipeline.viewports.first {
                size = CGSize(width: v.width, height: v.height) / scale
            } else {
                size = CGSize(width: 1355, height: 1087) //... ignore; hard coded
                return secondMenuFrame()
            }
        default:
            size = frame.size
        }
        setSize(size, onAppear: onAppear)
    }
}
#endif

