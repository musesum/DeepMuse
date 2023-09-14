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
#if os(xrOS)
#else
class CameraFacing {

    private var front˚: Flo?; var front: Bool = true

    init(_ root˚: Flo) {
        let camera = root˚.bind("shader.compute.camera")
        front˚ = camera.bind("front") { flo,_ in self.updateFacing(flo.bool) }
    }
    func updateFacing(_ front: Bool) {
        self.front = front
        MetCamera.shared.facing(front)
    }
}
#endif
