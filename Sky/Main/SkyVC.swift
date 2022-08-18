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
            MenuView(menuVm: MenuSkyVm(corner: [.lower, .left],
                                       axis: .vertical,
                                      rootTr3: SkyTr3.shared.root))
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
        let menuSkyView = UIHostingController(rootView: MenuSkyView())
        view.addSubview(menuSkyView.view)
        menuSkyView.view.translatesAutoresizingMaskIntoConstraints = false
        menuSkyView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        menuSkyView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        menuSkyView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        menuSkyView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        menuSkyView.view.backgroundColor = .clear

        // add touches 
        menuSkyView.view.addSubview(SkyView.shared)

        let tr3Root = SkyTr3.shared.root
        SkyDraw.shared.bindTr3(tr3Root)
        SkyMetal.shared.makeShader(for: tr3Root)

        let _ = SkyMain.shared

        // MuAudio.shared.test()
        // ?? MuMidi.shared.test(root: tr3Root)
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
