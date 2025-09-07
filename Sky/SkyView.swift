// created by musesum on 9/14/23.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation

struct SkyView <Content: View>: View  {

    @Environment(\.scenePhase) var scenePhase
    let id = Visitor.nextId()
    let content: () -> Content
    let menuVms: [MenuVm]
    let skyModel: SkyModel
    let nextFrame: NextFrame
    let glassState: GlassState
    let panicState: PanicState

    public init(_ skyModel: SkyModel, @ViewBuilder content: @escaping () -> Content) {

        self.skyModel = skyModel
        self.content = content

        self.nextFrame = skyModel.nextFrame
        self.menuVms = skyModel.menus.menuVms
        self.glassState = GlassState(skyModel.root˚)
        self.panicState = PanicState(skyModel.root˚, nextFrame)
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyModel)
    }

    func changedGeoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        DebugLog { P("🎬 SkyView changed geometry ") }
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        skyModel.setFrame(frame, insets, onAppear: onAppear)
    }

    func changedScene(_ phase: ScenePhase, changed: Bool) {

        DebugLog {
            var msg = "🎬 SkyView scenePhase: "
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
                content()
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
#if os(visionOS)
struct SkyVisionView: View {

    @Environment(ImmersionModel.self) var immersionModel
    let id = Visitor.nextId()
    let skyModel: SkyModel
    public init(_ skyModel: SkyModel) {
        self.skyModel = skyModel
    }
    var showVolumeView: Bool {

        let goImmersive = immersionModel.goImmersive
        let isImmersive = immersionModel.isImmersive
        NoDebugLog { P("🎬 SkyView go/is Immersive: \(goImmersive)/\(isImmersive) id: \(id)") }
        return !goImmersive
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            if showVolumeView {
                VolumeView(skyModel.pipeline)
            }
            SkyView(skyModel) {}

                Button {
                    immersionModel.goImmersive.toggle()
                } label: {
                    Image(immersionModel.goImmersive 
                          ? "icon.room.white"
                          : "icon.galaxy.white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                }
                .offset(x: 0, y: -20)
                .padding(6)
        }
    }
}
#else
struct SkyTouchView: View {

    let id = Visitor.nextId()
    let skyModel: SkyModel
    let touchView: TouchViewRepresentable!

    public init(_ skyModel: SkyModel) {
        self.skyModel = skyModel
        let menuVms = skyModel.menus.menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyModel.touchView)
    }

    var body: some View {
        GeometryReader { geo in
            SkyView(skyModel) {
                touchView
                    .cornerRadius(40)
                    .frame(width: Menu.touchWidth(geo),
                           height: Menu.touchHeight(geo))
                    .offset(Menu.touchOffset(geo))
            }
        }
    }
}
#endif
