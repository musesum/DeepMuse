//
//  AppDelegate.swift
//  MuseSky
//
//  Created by warren on 9/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//
import AudioKit
import UIKit
import BackgroundTasks

//???? @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.deepmuse.snapshot", using: nil)  { task in
            if let task = task as? BGAppRefreshTask {
                self.handleSnapshot(task: task)
            }
        }
        return true
    }
    func applicationWillResignActive(_ application: UIApplication) {

        scheduleSnapshot()
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
    /// take a snapshot of current
    func handleSnapshot(task: BGAppRefreshTask) {
        SkyVm.shared.saveSkyArchive() {
            task.setTaskCompleted(success: true)
        }
    }

    /**
     Setup `SceneDelegate` to use `HostingController` to remove annoying taskbar.
     */
    class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
        func application(_ application: UIApplication,
                         configurationForConnecting connectingSceneSession: UISceneSession,
                         options: UIScene.ConnectionOptions) -> UISceneConfiguration {

            let config = UISceneConfiguration(name: "MainScene", sessionRole: .windowApplication)
            config.delegateClass = SceneDelegate.self
            return config
        }
    }

//    // MARK: UISceneSession Lifecycle
//    func application(_ application: UIApplication, 
//                     configurationForConnecting connectingSceneSession: UISceneSession,
//                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

}
