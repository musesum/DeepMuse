import MetalKit
import MuUtilities
import UIKit
import Par
import Tr3

import MuMenu
import MuMenuSky
import SwiftUI

struct ContentView: View {

    var body: some View {
        // ContentView())
        ZStack(alignment: .bottomLeading) {
            //CanvasView()
            MenuView(menuVm: MenuSkyVm(corner: [.lower, .left], axis: .vertical))
            //MenuView(menuVm: MenuSkyVm(corner: [.lower, .right], axis: .vertical))

            //MenuView(menuVm: MenuSkyVm(corner: [.upper, .left], axis: .horizontal))
            //MenuView(menuVm: MenuSkyVm(corner: [.upper, .right], axis: .horizontal))
            //MenuView(menuVm: MenuSkyVm(corner: [.lower, .right], axis: .vertical))
            //MenuView(menuVm: MenuSkyVm(corner: [.upper, .right], axis: .horizontal))
            //MenuView(menuVm: TestVm(corner: [.upper, .left]))
            //MenuView(menuVm: TestVm(corner: [.upper, .right]))
        }
        .statusBar(hidden: true)
    }
}

class SkyVC: UIViewController {

    static var shared = SkyVC()
    private var uiOrientation: UIInterfaceOrientation { get {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait }
    }
    override func viewDidAppear(_ animated: Bool) {

        let bounds = UIScreen.main.bounds
        MuOrientation.shared.uiOrientation = uiOrientation
        view = SkyPipeline.shared.setViewFrame(bounds)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        let skyView = SkyView.shared
        view.addSubview(skyView)

        // add menu
        let contentView = UIHostingController(rootView: ContentView())
        view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

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
            ? UIInterfaceOrientationMask.all
            : UIInterfaceOrientationMask.all
        }
    }

    override var shouldAutorotate: Bool { false }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }

}
