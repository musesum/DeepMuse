// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuPeers
import MuHands

@MainActor
class AppModel {

    let root˚: Flo
    let peers: Peers
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame
    let skyVm: SkyVm

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
        let camera = CameraSession(nil, position: .front)
        #endif
        self.skyVm = SkyVm(root˚, .windowed, archiveVm, peers, scale, bounds, camera)

    }
}

#if os(visionOS)

class VisionModel: AppModel {

    var handsModel: HandsModel!
    var handsTracker: HandsTracker!
   
    override init () {
        super.init()
        self.handsModel = HandsModel(skyVm.touchCanvas, skyVm.root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }
    func setImmersion(_ immersion: Bool) {
        skyVm.setImmersion(immersion)
    }

    func openURL(_ url: URL) {
        skyVm.readUserArchive(url, nextFrame, local: false)
    }
}
#endif

