// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame, TapeFlo
import MuVision
import MetalKit
import MuMenu
import MuPeers
import MuHands


@MainActor
class AppModel: Sendable {

    let root˚: Flo
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame
    let skyModel: SkyModel
    let peers: Peers

    init () {
        self.root˚ = Flo("√")
        self.peers = Peers(PeersConfig(service: "_deepmuse-peer._tcp",
                                        secret: ""), // replace with a real secret
                           logging: false)
        peers.setupPeers()
        self.nextFrame = NextFrame()
        self.archiveVm = ArchiveVm(nextFrame)
        #if os(visionOS)
        let bounds = CGRect.zero
        let scale: CGFloat = 3
        let camera = CameraSession()
        #else
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let camera = CameraSession(nil, position: .front, nextFrame)
        #endif
        self.skyModel = SkyModel(root˚, .windowed, archiveVm, peers, scale, bounds, camera)

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
        skyModel.readUserArchive(url, nextFrame, local: false)
    }
}
#endif

