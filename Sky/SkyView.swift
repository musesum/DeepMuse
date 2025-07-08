// created by musesum on 9/14/23.


import SwiftUI
import BackgroundTasks
import MuFlo
import MuVision
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
open class SkyMenu {

    private var left˚  : Flo? ; var left = true
    private var right˚ : Flo? ; var right = true

    init(_ root˚: Flo) {
        let menu = root˚.bind("hand.menu")
        left˚  = menu.bind("left" ) { f,_ in self.left  = f.bool }
        right˚ = menu.bind("right") { f,_ in self.right = f.bool }
    }

}
struct SkyView: View {

    @Environment(\.scenePhase) var scenePhase
    #if os(visionOS)
    @Environment(ImmersionModel.self) var immersionModel
    #endif

    let id = Visitor.nextId()
    var menuVms: [MenuVm]
    let skyCanvas: SkyCanvas
    let nextFrame: NextFrame
    let peers: Peers
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    let touchView: TouchViewRepresentable!
    var viewing: Viewing
    var skyMenu: SkyMenu
    var immersive: Bool = false

    public init(_ skyCanvas: SkyCanvas,
                _ viewing: Viewing,
                _ peers: Peers) {

        self.skyCanvas = skyCanvas
        self.viewing = viewing
        self.nextFrame = skyCanvas.nextFrame
        self.peers = peers
        self.menuVms = MenuVms(skyCanvas.root˚, skyCanvas.archiveVm, peers).menuVms
        self.touchView = TouchViewRepresentable(menuVms, skyCanvas.touchView)
        self.skyMenu = SkyMenu(skyCanvas.root˚)
        nextFrame.addFrameDelegate("SkyCanvas".hash, skyCanvas)
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
            .onChange(of: geo.frame(in: .global)) { geoFrame(geo, onAppear: false) 
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                DebugLog { P("🎬 MenuTouchView 🟢") }
                nextFrame.pause = false
            case .inactive:
                DebugLog { P("🎬 MenuTouchView 🔴") }
                skyCanvas.saveArchive("Snapshot", "autosaved") {
                    nextFrame.pause = true
                }
            default:  break
            }
        }
    }
}
