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
        self.handsModel = HandsModel(skyModel.touchCanvas, skyModel.root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }
    func setImmersion(_ immersion: Bool) {
        skyModel.setImmersion(immersion)
    }

    func openURL(_ url: URL) {
        skyModel.readUserArchive(url, local: false)
    }
}
#endif

