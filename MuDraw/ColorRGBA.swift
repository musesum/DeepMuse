//  Created by warren on 7/17/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import QuartzCore

struct ColorRGBA {

    var red   = CGFloat(1)
    var green = CGFloat(1)
    var blue  = CGFloat(1)
    var alpha = CGFloat(1)

    init (_ red:   CGFloat = 1,
          _ green: CGFloat = 1,
          _ blue:  CGFloat = 1,
          _ alpha: CGFloat = 1) {

        self.red   = red
        self.green = green
        self.blue  = blue
        self.alpha = alpha
    }
}

