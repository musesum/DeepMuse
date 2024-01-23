//  created by musesum on 9/22/19.

import SwiftUI
import BackgroundTasks
import MuFlo
import MuAudio
import MuMenu
import MuSkyFlo

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /// setup `HostingController` here:
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = MenuSkyView.shared.hostingC
            self.window = window
            window.makeKeyAndVisible()
            window.backgroundColor = .blue
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        NextFrame.shared.pause = false
    }

    func sceneWillResignActive(_ scene: UIScene) {
        NextFrame.shared.pause = true
        SkyVm.shared.saveSkyArchive() {
            //????
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
