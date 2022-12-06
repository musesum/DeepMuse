
import UIKit
import SwiftUI
import Tr3
import MultipeerConnectivity
import MuMenu

class SkyVC: UIViewController {

    static var shared = SkyVC()
    var tr3Root = SkyTr3.shared.root
    var touchDraw = TouchDraw(SkyTr3.shared.root)
    var peerData˚: Tr3?

    override func viewDidAppear(_ animated: Bool) {

        let bounds = UIScreen.main.bounds
        view.addSubview(SkyPipeline.shared.setViewFrame(bounds))
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setupMenuView()

        SkyMetal.shared.makeShader(for: tr3Root)
        let _ = SkyMain.shared
        // MuAudio.shared.test()
        MuMidi.shared.test(root: tr3Root)

        setupMultiPeerSession()
        peerData˚ = SkyTr3.shared.root.bindPath("sky.main.peer.data") { t, _ in
            #if false
            if PeersVm.shared.peersList != "" {
                if let val = t.val,
                   let tr3From = val.tr3 {
                   let path = tr3From.parentPath(99)
                    let hash = tr3From.hash
                    let script = val.scriptVal([.def,.now])
                    print("⚡️\(path)#\(hash):(\(script))")
                }
            }
            #endif
        }
    }
    /// browse peers that have advertised prescence,
    /// which the user manually selects to send an invitation
    func invitePeers() {

    }

    func setupMultiPeerSession() {

    }
    func setupMenuView() {
        // add menu
        let menuView = UIHostingController(rootView: MenuSkyView())
        view.addSubview(menuView.view)
        menuView.view.translatesAutoresizingMaskIntoConstraints = false
        menuView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        menuView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        menuView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        menuView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        menuView.view.backgroundColor = .clear
    }
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get {
            UIDevice.current.userInterfaceIdiom == .phone
            ? UIInterfaceOrientationMask.allButUpsideDown
            : UIInterfaceOrientationMask.all
        }
    }
    override var shouldAutorotate: Bool { false }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
}
