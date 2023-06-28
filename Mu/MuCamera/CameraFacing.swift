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
class CameraFacing {
    public static var shared = CameraFacing()

    private var front˚: Flo?; var front: Bool = true

    init() {
        let camera = SkyFlo.shared.root˚.bind("shader.compute.camera")
        front˚ = camera.bind("front") { flo,_ in self.updateFacing(flo.bool) }
    }
    func updateFacing(_ front: Bool) {
        self.front = front
        MetCamera.shared.facing(front)
    }
}
