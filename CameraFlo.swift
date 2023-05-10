//  Created by warren on 4/24/23.
//  Copyright © 2023 DeepMuse. All rights reserved.

import UIKit
import MuFlo

open class CameraFlo {

    static public let shared = CameraFlo()

    public let root = Flo.root

    var stream˚ : Flo?
    var facing˚ : Flo?
    var mask˚   : Flo?

    var stream = false
    var facing = false
    var mask   = false

    init() {

        guard let camera = root.findPath("model.canvas.camera") else { return }

        stream˚ = camera.bindPath("stream")
        facing˚ = camera.bindPath("facing")
        mask˚   = camera.bindPath("mask")

        stream˚?.addClosure { flo,_ in self.stream = flo.bool }
        facing˚?.addClosure { flo,_ in self.facing = flo.bool }
        mask˚?  .addClosure { flo,_ in self.mask   = flo.bool }
    }
}
