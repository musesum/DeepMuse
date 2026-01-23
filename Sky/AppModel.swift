// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // TapeFlo
import MuVision
import MetalKit
import MuMenu
import MuPeers
import MuHands

@MainActor
class AppModel: Sendable {

    public static var shared = AppModel()

    let root˚: Flo
    let archiveVm: ArchiveVm
    let skyModel: SkyModel
    let tapeFlo: TapeFlo

    init () {
        self.root˚ = Flo("√")
        self.tapeFlo = TapeFlo()
        self.archiveVm = ArchiveVm()
        #if os(visionOS)
        let bounds = CGRect.zero
        let scale  = CGFloat(3)
        let camera = CameraSession()
        #else
        let bounds = UIScreen.main.bounds
        let scale  = UIScreen.main.scale
        let camera = CameraSession(nil, position: .front)
        #endif
        self.skyModel = SkyModel(
            root˚,
            .windowed,
            archiveVm,
            tapeFlo,
            scale,
            bounds,
            camera)
        Peers.shared.setupPeers(tapeFlo)
    }
}

#if os(visionOS)

class VisionModel: AppModel {

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

