
import UIKit
import SwiftUI
import MuMenu
import MuAudio // MuMidi
import MuTime // NextFrame


class SkyVC: UIViewController {

    static var shared = SkyVC()
    var midi: MuMidi?
    var pipeline: SkyPipeline!
    let root˚ = SkyFlo.shared.root˚
    var touchView: SkyTouchView!
    var settingUp = true
    var hostView: UIView?
#if os(xrOS)
    let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
#else
    let bounds = UIScreen.main.bounds
#endif

    override func viewDidLoad() {
        midi = MuMidi(root: root˚)
        if let midi {
            TouchMidi.touchRemote = midi
        }
        // MuAudio.shared.test()
        pipeline = SkyPipeline(bounds)
        pipeline.makeShader(for: root˚)
        pipeline.setupPipeline()
    }

    override func viewDidAppear(_ animated: Bool) {

        setNeedsUpdateOfHomeIndicatorAutoHidden()
        view.layer.addSublayer(pipeline.metalLayer) 
        TouchCanvas.shared.touchFlo.parseRoot(root˚)
        touchView = SkyTouchView(bounds)
        let menuView = MenuView(root˚, touchView, self)
        hostView = UIHostingController(rootView: menuView).view
        
        if let hostView {
            view.addSubview(hostView)
            hostView.translatesAutoresizingMaskIntoConstraints = false
            hostView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            hostView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            hostView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            hostView.backgroundColor = UIColor.clear
        }
        NextFrame.shared.addFrameDelegate("SkyVC".hash, self)
        
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

extension SkyVC: MenuDelegate {

    func window(bounds: CGRect) {
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        //???view.frame = frame
        TouchCanvas.shared.touchFlo.viewSize = bounds.size
        if let touchView {
            touchView.frame = frame
        }
        let scale = view.contentScaleFactor
        pipeline.resize(bounds, scale)

    }
}
extension SkyVC: NextFrameDelegate {
    func nextFrame() -> Bool {
        pipeline.draw()
        return true
    }
    func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }
    
}
