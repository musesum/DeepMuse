import MetalKit
import MuUtilities
import UIKit
import Par
import Tr3
import Tr3Thumb

class SkyVC: UIViewController {

    static var shared = SkyVC()
    private var uiOrientation: UIInterfaceOrientation { get {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait }
    }
    override func viewDidAppear(_ animated: Bool) {

        let window = self.view.window
        let insets = window?.safeAreaInsets
        let bounds = UIScreen.main.bounds
        MuOrientation.shared.uiOrientation = uiOrientation 
        view = SkyPipeline.shared.setViewFrame(bounds)
        setNeedsUpdateOfHomeIndicatorAutoHidden()

        // add dock
        let skyView = SkyView.shared
        let thumbDock = ThumbDock(skyView, insets)
        let tr3Root = SkyTr3.shared.root
        let _ = SkyDock(thumbDock, tr3Root)
        view.addSubview(skyView)
        SkyDraw.shared.bindTr3(tr3Root)
        let _ = SkyMain.shared

        // MuAudio.shared.test()
        MuMidi.shared.test(root: tr3Root)
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get {
            if UIDevice.current.userInterfaceIdiom == .phone {
                return UIInterfaceOrientationMask.all
            }
            else {
                return UIInterfaceOrientationMask.all
            }
        }
    }

    override var shouldAutorotate: Bool { false }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }

}
