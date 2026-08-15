// created by musesum on 9/14/23.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation
#if os(iOS)
import MuDisplay
#endif

struct SkyView: View {

    @Environment(\.scenePhase) var scenePhase

    let id = Visitor.nextId()
    let cornerVms: [CornerVm]
    let touchView: TouchViewRepresentable!
    let panicState: PanicState
    #if os(iOS)
    @StateObject private var externalDisplay = ExternalDisplayManager()
    #endif

    public init() {
        let skyModel = SkyModel.shared
        let menuVms = skyModel.menus.menuVms
        self.cornerVms = menuVms.map { $0.rootVm.cornerVm }
        self.touchView = TouchViewRepresentable(menuVms, skyModel.touchView)
        self.panicState = PanicState(skyModel.root˚)
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyModel)
    }

    func changedGeoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        DebugLog { P("🎬 SkyView changed geometry ") }
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        SkyModel.shared.setFrame(frame, insets, onAppear: onAppear)
    }
    func touchWidth(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width +
        geo.safeAreaInsets.leading +
        geo.safeAreaInsets.trailing
    }
    func touchHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.height +
        geo.safeAreaInsets.top +
        geo.safeAreaInsets.bottom
    }
    func touchOffset(_ geo: GeometryProxy) -> CGSize {
        CGSize(width:  -geo.safeAreaInsets.leading,
               height: -geo.safeAreaInsets.top)
    }

    func changedScene(_ phase: ScenePhase, changed: Bool) {

        DebugLog {
            var msg = "🎬 SkyView scenePhase: "
            switch phase {
            case .active     : msg += "🟢 .active id: \(id)"
            case .inactive   : msg += "🔴 .inactive"
            case .background : msg += "🔵 .background"
            @unknown default : break
            }
            P(msg)
        }
        if changed {
            switch phase {
            case .active: NextFrame.shared.pause = false
            case .inactive: SkyModel.shared.saveArchive("Snapshot", "autosaved") { NextFrame.shared.pause = true }
            default:  break
            }
        }
    }

    var body: some View {

        GeometryReader { geo in
            Group {
                touchView
                    .cornerRadius(40)
                    .frame(width: touchWidth(geo), height: touchHeight(geo))
                    .offset(touchOffset(geo))
                if scenePhase != .active {
                    ZStack {
                        Image("icon.ring")
                            .scaleEffect(0.33)
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if !SkyModel.shared.startup.done {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                if SkyModel.shared.startup.menusReady {
                    SkyModel.shared.menuView
                        .background(.clear)
                        .persistentSystemOverlays(.hidden)
                }
            }
            .onAppear() {
                changedScene(scenePhase, changed: false)
                changedGeoFrame(geo, onAppear: true)
            }
            .onChange(of: scenePhase) { changedScene($1, changed: true) }
            .onChange(of: geo.frame(in: .global)) { changedGeoFrame(geo, onAppear: false) }
            #if os(iOS)
            .sheet(isPresented: $externalDisplay.showChoice) {
                // present even with no display attached (Living parity) —
                // the chooser renders Mirror/Extend with an empty resolution list
                ExternalDisplayChooser(
                    resolutions: externalDisplay.externalScreen.map {
                        DisplayModeProvider.resolutions(for: $0) } ?? [],
                    currentSize: externalDisplay.currentSize,
                    initialMode: externalDisplay.mode,
                    onChoose: { externalDisplay.choose($0) },
                    onResolution: { externalDisplay.applyResolution($0) })
            }
            #endif
        }
    }
}


