// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuPeers

struct Viewing: OptionSet {
    let rawValue: Int

    static let canvas = Viewing(rawValue: 1 << 0)
    static let menu   = Viewing(rawValue: 1 << 1)
    static let hands  = Viewing(rawValue: 1 << 2)
    static let left   = Viewing(rawValue: 1 << 3)
    static let right  = Viewing(rawValue: 1 << 4)

    var canvas : Bool { contains(.canvas ) }
    var menu   : Bool { contains(.menu   ) }
    var hands  : Bool { contains(.hands  ) }
    var left   : Bool { contains(.left   ) }
    var right  : Bool { contains(.right  ) }
}

@MainActor
class AppModel {

    let root˚: Flo
    let peers: Peers
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame
    let skyCanvas: SkyCanvas
    let skyView: SkyView

    init () {
        self.root˚ = Flo("√")
        self.peers = Peers(PeersConfig(
            service: "_deepmuse-peer._tcp",
            secret: "")) // replace with a real secret
        peers.setupPeers()
        self.nextFrame = NextFrame()
        self.archiveVm = ArchiveVm(nextFrame)
        #if os(visionOS)
        let bounds = CGRect.zero
        let scale: CGFloat = 3
        #else
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        #endif
        self.skyCanvas = SkyCanvas(root˚, .windowed, archiveVm, peers, scale, bounds)
        self.skyView = SkyView(skyCanvas, [.canvas,.menu,.left,.right], peers)
        skyCanvas.skyView = skyView
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
        skyCanvas.skyView = SkyView(skyCanvas, [.canvas,.menu,.hands,.left,.right], peers)

    }
    func setImmersion(_ immersion: Bool) {
        skyCanvas.setImmersion(immersion)
    }

    func openURL(_ url: URL) {
        skyCanvas.readUserArchive(url, nextFrame, local: false)
    }
}
#endif

