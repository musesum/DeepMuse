//
//  CameraFlip.swift
//  DeepMuse
//
//  Created by warren on 3/8/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation
import MuFlo
import MuMetal
class CameraFlip {
    public static var shared = CameraFlip()

    private var cameraFlip˚: Flo?

    init() {
        let camera = SkyFlo.shared.root˚.bind("shader.compute.camera")
        cameraFlip˚ = camera.bind("flip") { f,_ in MetCamera.shared.flipCamera() }
    }
}
