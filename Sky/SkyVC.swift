
import UIKit
import SwiftUI
import MuMenu

class SkyVC: UIViewController {

    static var shared = SkyVC()
    var midi: MuMidi?
    var pipeline: SkyPipeline?

    override func viewDidAppear(_ animated: Bool) {

        pipeline = SkyPipeline.shared

        setNeedsUpdateOfHomeIndicatorAutoHidden()

        let root˚ = SkyFlo.shared.root˚
        if let pipeline {
            view.addSubview(pipeline.mtkView)
            pipeline.makeShader(for: root˚)
            pipeline.setupPipeline()
            pipeline.settingUp = false
        }
        setupMenuView()
        let _ = SkyMain.shared
        // MuAudio.shared.test()
        SkyVC.shared.midi = MuMidi(root: root˚)
    }

    func setupMenuView() {
        let touchDraw = TouchDraw.shared
        let touchView = SkyTouchView(touchDraw.drawPoint,
                                     touchDraw.drawRadius,
                                     touchDraw)
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
