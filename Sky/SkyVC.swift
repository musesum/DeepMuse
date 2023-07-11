
import UIKit
import SwiftUI
import MuMenu
import MuAudio // MuMidi

class SkyVC: UIViewController {

    static var shared = SkyVC()
    var midi: MuMidi?
    var pipeline = SkyPipeline.shared
    var touchDraw = TouchDraw(SkyFlo.shared.root˚, SkyPipeline.shared.viewSize)
    let root˚ = SkyFlo.shared.root˚

    override func viewDidLoad() {
        let _ = SkyMain.shared
        midi = MuMidi(root: root˚)
        // MuAudio.shared.test()
    }
    
    override func viewDidAppear(_ animated: Bool) {

        setNeedsUpdateOfHomeIndicatorAutoHidden()

            view.addSubview(pipeline.mtkView)
            pipeline.makeShader(for: root˚)
            pipeline.setupPipeline()
            pipeline.settingUp = false

        let touchView = SkyTouchView(touchDraw)
        let menuView = MenuView(SkyFlo.shared.root˚, touchView)
        let hostView = UIHostingController(rootView: menuView).view
        if let hostView {
            view.addSubview(hostView)
            hostView.translatesAutoresizingMaskIntoConstraints = false
            hostView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            hostView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            hostView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            hostView.backgroundColor = .clear
        }
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
