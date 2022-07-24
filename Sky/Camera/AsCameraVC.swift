//
//  ViewController.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 24/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import Metal
import MetalKit

internal final class AsCameraVC: AsMtkVC {
    var session: AsMetalCameraSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        session = AsMetalCameraSession(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session?.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stop()
    }
}

// MARK: - AsMetalCameraSessionDelegate
extension AsCameraVC: AsMetalCameraSessionDelegate {
    func metalCameraSession(_ session: AsMetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        self.texture = textures[0]
    }

    func metalCameraSession(_ cameraSession: AsMetalCameraSession, didUpdateState state: MetalCameraSessionState, error: MetalCameraSessionError?) {

        if error == .captureSessionRuntimeError {
            // In this app we are going to ignore capture session runtime errors
            cameraSession.start()
        }

        DispatchQueue.main.async {
            self.title = "Metal camera: \(state)"
        }

        NSLog("Session changed state to \(state) with error: \(error?.localizedDescription ?? "None").")
    }
}
