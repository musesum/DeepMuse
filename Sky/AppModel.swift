// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuPeer

class AppModel: ObservableObject {

    let root˚: Flo
    let peers: Peers
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame
    let skyCanvas: SkyCanvas
    let skyView: SkyView


    init () {
        self.root˚ = Flo("√")
        self.peers = Peers("Sky")
        self.nextFrame = NextFrame()
        self.archiveVm = ArchiveVm(nextFrame)
        self.skyCanvas = SkyCanvas(root˚, .windowed, archiveVm, peers, /*scale*/ 3, .zero)
        self.skyView = SkyView(skyCanvas, peers)
    }
}


#if os(visionOS)

class VisionModel: AppModel {

    var handsModel: HandsModel!
    var handsTracker: HandsTracker!

    override init () {
        super.init()
        self.handsModel = HandsModel(skyCanvas.touchCanvas, skyCanvas.root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }
    func setImmersion(_ immersion: Bool) {
        skyCanvas.setImmersion(immersion)
    }

    func openURL(_ url: URL) {
        skyCanvas.readUserArchive(url, nextFrame, local: false)
    }
}
#endif
