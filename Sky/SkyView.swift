// created by musesum on 9/14/23.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
import MuMenu
import MuPeers
import Observation

struct SkyView: View {

    @Environment(\.scenePhase) var scenePhase
    #if os(visionOS)
    @Environment(ImmersionModel.self) var immersionModel
    #endif


    let id = Visitor.nextId()
    var menuVms: [MenuVm]
    let skyCanvas: SkyCanvas
    let peers: Peers
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    let touchView: TouchViewRepresentable!
    var immersive: Bool = false

    public init(_ skyCanvas: SkyCanvas,
                _ peers: Peers) {

        self.skyCanvas = skyCanvas
        self.peers = peers
        self.menuVms = MenuVms(skyCanvas.root˚, skyCanvas.archiveVm, peers).menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyCanvas.touchView)
    }

    func geoFrame(_ geo: GeometryProxy, onAppear: Bool) {
        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        skyCanvas.setFrame(frame, insets, onAppear: onAppear)
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

    var showTouchView: Bool {
        #if os(visionOS)
        let immersive = immersionModel.goImmersive
        DebugLog { P("꩜ immersive: \(immersive)") }
        return !immersive
        #else
        return true
        #endif
    }

    var body: some View {
        
        GeometryReader { geo in
            Group {
                if showTouchView {
                    touchView
                        .cornerRadius(40)
                        .frame(width: touchWidth(geo), height: touchHeight(geo))
                        .offset(touchOffset(geo))
                }
                MenuView(menuVms)

                    .background(.clear)
                    #if os(iOS)
                    .persistentSystemOverlays(.hidden)
                    #endif
            }
            .onAppear { geoFrame(geo, onAppear: true) }
            .onChange(of: geo.frame(in: .global)) { geoFrame(geo, onAppear: false) }
        }
        
    }
}

