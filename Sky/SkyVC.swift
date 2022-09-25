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

        let rootTr3 = SkyTr3.shared.root
        let leftVm  = MenuSkyVm([.lower, .left],  .vertical, rootTr3)
        let rightVm = MenuSkyVm([.lower, .right], .vertical, rootTr3)

        ZStack(alignment: .bottomLeading) {
            
            // add touch handler
            TouchViewRepresentable([leftVm.rootVm.touchVm, rightVm.rootVm.touchVm])
            // Menus via UITouch (not SwiftUI's DragGesture)
            MenuTouchView(menuVm: leftVm)
            MenuTouchView(menuVm: rightVm)
        }
        .statusBar(hidden: true)
    }
}

class SkyVC: UIViewController {

    static var shared = SkyVC()
    var tr3Root = SkyTr3.shared.root
    var touchDraw = TouchDraw(SkyTr3.shared.root)

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
