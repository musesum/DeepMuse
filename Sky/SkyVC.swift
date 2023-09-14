
import UIKit
import SwiftUI

class SkyVC: UIViewController {

    override func viewDidLoad() {
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewDidAppear(_ animated: Bool) {
        let skyVm = SkyVm.shared
        guard let pipeline = skyVm.pipeline else { return }

        view.layer.addSublayer(pipeline.metalLayer)

//        if let hostView = skyVm.hostView {
//            view.addSubview(hostView)
//            hostView.translatesAutoresizingMaskIntoConstraints = false
//            hostView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//            hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//            hostView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//            hostView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//            hostView.backgroundColor = UIColor.clear
//        }
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
