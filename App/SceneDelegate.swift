//
//  SceneDelegate.swift
//  MuseSky
//
//  Created by warren on 9/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import UIKit
import SwiftUI
import BackgroundTasks
import MuFlo
import MuAudio
import MuMenu
import MuSkyFlo

struct MenuSkyView: View {

    public static let shared = MenuSkyView()
    var menuView: MenuView!
    var midi: MuMidi?
    var pipeline: SkyPipeline?
    var touchView: SkyTouchView!
    var settingUp = true

    let archive = FloArchive(bundle: MuSkyFlo.bundle,
                             archive: "Snapshot",
                             scripts:  ["sky", "shader", "model", "menu", "plato", "cube", "midi", "corner"],
                             textures: ["draw"])

    public init() {
        midi = MuMidi(root: archive.root˚)
        if let midi {
            TouchMidi.touchRemote = midi
        }
        _ = MuAudio.shared // MuAudio.shared.test()
#if os(xrOS)
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
#else
        let bounds = UIScreen.main.bounds
#endif
        pipeline = SkyPipeline(bounds, archive.root˚)
        TouchCanvas.shared.touchFlo.parseRoot(archive.root˚, archive)
        touchView = SkyTouchView(bounds)
       //??? menuView = MenuView(archive.root˚, touchView, self)
       //        hostView = UIHostingController(rootView: menuView).view
        NextFrame.shared.addFrameDelegate("Sky".hash, self)
    }

    var body: some View {
        VStack {
            MenuView(archive.root˚, touchView, self)
                .background(.secondary)
        }
    }
}
extension MenuSkyView: MenuDelegate {

    func window(bounds: CGRect, insets: EdgeInsets) {

        let width = bounds.width + insets.leading + insets.trailing
        let height = bounds.height + insets.top + insets.bottom
#if os(xrOS)
        let scale = CGFloat(3) //??? scale
#else
        let scale = UIScreen.main.scale
#endif
        let viewSize = CGSize(width: width * scale, height: height * scale)
        TouchCanvas.shared.touchFlo.viewSize = viewSize
        touchView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        pipeline?.resize(viewSize, scale)
    }
}
extension MenuSkyView: NextFrameDelegate {

    func nextFrame() -> Bool {
        pipeline?.draw()
        return true
    }
    func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }

}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /// setup `HostingController` here:
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let hostingController = HostingController(rootView: MenuSkyView.shared)
            window.rootViewController = hostingController
            self.window = window
            window.makeKeyAndVisible()
        }
    }

//????    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//
//        guard let _ = (scene as? UIWindowScene) else { return }
//    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        NextFrame.shared.pause = false
    }

    func sceneWillResignActive(_ scene: UIScene) {
        NextFrame.shared.pause = true
        SkyVm.shared.saveSkyArchive() {
        }
    }

    func scheduleSnapshot() {
        let request = BGAppRefreshTaskRequest(identifier: "com.deepmuse.snapshot")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 0)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
     }

    func sceneDidEnterBackground(_ scene: UIScene) {
        //?? scheduleSnapshot()
        SkyVm.shared.saveSkyArchive() {
            //?? task.setTaskCompleted(success: true)
        }
    }

}

/**
 remove annoying taskbar via `prefersHomeIndicatorAutoHidden`
 */
class HostingController: UIHostingController<MenuSkyView> {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
