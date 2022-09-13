import MetalKit
import MuUtilities
import UIKit
import Par
import Tr3

import MuMenu
import MuMenuSky
import SwiftUI

struct MenuSkyView: View {

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SkyViewUI()
            MenuView(menuVm: MenuSkyVm(corner: [.lower, .left],
                                       axis: .vertical,
                                       rootTr3: SkyTr3.shared.root))

            MenuView(menuVm: MenuSkyVm(corner: [.lower, .right],
                                       axis: .vertical,
                                       rootTr3: SkyTr3.shared.root))
            //??? .onAppear(perform: UIApplication.shared.addGestureRecognizer)
        }
        
        .statusBar(hidden: true)
    }
}

class SkyVC: UIViewController {

    static var shared = SkyVC()

    override func viewDidAppear(_ animated: Bool) {

        let bounds = UIScreen.main.bounds
        view = SkyPipeline.shared.setViewFrame(bounds)
        setNeedsUpdateOfHomeIndicatorAutoHidden()

        // add menu
        let menuView = UIHostingController(rootView: MenuSkyView())
        view.addSubview(menuView.view)
        menuView.view.translatesAutoresizingMaskIntoConstraints = false
        menuView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        menuView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        menuView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        menuView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        menuView.view.backgroundColor = .clear

        // add touches
        menuView.view.addSubview(SkyView.shared)

        let tr3Root = SkyTr3.shared.root
        SkyDraw.shared.bindTr3(tr3Root)
        SkyMetal.shared.makeShader(for: tr3Root)

        let _ = SkyMain.shared

        //?? MuAudio.shared.test()
        //?? MuMidi.shared.test(root: tr3Root)
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
