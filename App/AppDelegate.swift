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

@UIApplicationMain
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
        SkyPipeline.shared.saveSkyArchive("Snapshot") {
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
