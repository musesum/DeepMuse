// created by musesum on 9/14/23.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation

struct SkyView: View  {

    @Environment(\.scenePhase) var scenePhase
    let id = Visitor.nextId()
    let menuVms: [MenuVm]
    let skyModel: SkyModel
    let nextFrame: NextFrame
    let glassState: GlassState
    let panicState: PanicState

    public init(_ skyModel: SkyModel) {

        self.skyModel = skyModel
        self.nextFrame = skyModel.nextFrame
        self.menuVms = skyModel.menus.menuVms
        self.glassState = GlassState(skyModel.root˚)
        self.panicState = PanicState(skyModel.root˚, nextFrame)
        nextFrame.addFrameDelegate("SkyView".hash, skyModel)
    }

    func changedGeoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        DebugLog { P("🎬 SkyView changed geometry ") }
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        skyModel.setFrame(frame, insets, onAppear: onAppear)
    }

    func changedScene(_ phase: ScenePhase, changed: Bool) {

        DebugLog {
            var msg = "🎬 ScenePhase: "
            switch phase {
            case .active     : msg += "🟩 .active id: \(id)"
            case .inactive   : msg += "🟥 .inactive"
            case .background : msg += "🟦 .background"
            @unknown default : break
            }
            P(msg)
        }
        if changed {
            switch phase {
            case .active: nextFrame.pause = false
            case .inactive: skyModel.saveArchive("Snapshot", "autosaved") { nextFrame.pause = true }
            default:  break
            }
        }
    }
    var body: some View {
        GeometryReader { geo in
            Group {
                MenuView(menuVms)
                    .environmentObject(glassState)
                    .background(.clear)
            }
            .onAppear() {
                changedScene(scenePhase, changed: false)
                changedGeoFrame(geo, onAppear: true)
            }
            .onChange(of: scenePhase) { changedScene($1, changed: true) }
            .onChange(of: geo.frame(in: .global)) { changedGeoFrame(geo, onAppear: false) }
        }
    }
}
