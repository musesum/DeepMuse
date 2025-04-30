// created by musesum on 4/10/25

import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuPeer

#if os(visionOS)

final class VisionModel: ObservableObject {
    let root˚: Flo
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame
    let skyCanvas: SkyCanvas
    let peers: Peers
    let skyView: SkyView
    let handsModel: HandsModel
    let handsTracker: HandsTracker

    var renderState: RenderState

    init(_ renderState: RenderState) {
        self.renderState = renderState
        self.nextFrame = NextFrame()
        self.root˚ = Flo("√")
        self.peers = Peers("Sky")
        self.archiveVm = ArchiveVm(nextFrame)
        self.skyCanvas = SkyCanvas(root˚, .windowed, archiveVm, peers, /*scale*/ 3, .zero)
        self.skyView = SkyView(skyCanvas, peers)
        self.handsModel = HandsModel(skyCanvas.touchCanvas, skyCanvas.root˚)
        self.handsTracker = HandsTracker(handsModel.handsFlo)
    }
    func setImmersion(_ immersion: Bool) {

        renderState = immersion ? .immersed : .windowed
        skyCanvas.setRenderState(renderState)
        skyCanvas.nextFrame.pause = immersion
    }

    func startHands() async {
        await handsTracker.startHands()
        await handsTracker.updateHands()
        await handsTracker.monitorSessionEvents()
    }
    func openURL(_ url: URL) {
        skyCanvas.readUserArchive(url, nextFrame, local: false)
    }
}
#endif
