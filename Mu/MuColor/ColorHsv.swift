//  Created by warren on 7/30/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation

public struct Hsv {

    internal var h: Float // 0 ..360 // degree instead of radians
    internal var s: Float // 0...100
    internal var v: Float // 0...100

    init(_ h: Float, _ s: Float, _ v: Float) {

        self.h = h
        self.s = s
        self.v = v
    }
    func rgb() -> Rgb {

        if s == 0 { return Rgb(v/100, v/100, v/100) }

        let ss = s / 100    // normalize saturation 0...100 to 0...1
        let vv = v / 100    // normalize value 0...100 to 0...1
        if( ss == 0 ) { return Rgb(vv, vv, vv) }

        let h6 = h / 60     // divide hue 0..<360 into 6 sections 0..<6
        let hi = floor(h6)  // integer part of hue
        let hf = h6 - hi    // fractional part of hue for gradient
        let v0 = vv * (1 - ss ) // fixed component value for section
        let v1 = vv * (1 - ss * hf ) // component ramp up
        let v2 = vv * (1 - ss * ( 1 - hf ) ) // ramp down

        var r = Float.zero
        var g = Float.zero
        var b = Float.zero

        ///    `r   g   b   r`
        ///    ` ╲ ╱ ╲ ╱ ╲ ╱ `
        ///    ` ╱ ╲ ╱ ╲ ╱ ╲ `
        ///    `0 1 2 3 4 5 6`
        switch hi  { // which of 6 sections
        case 0: r = vv; g = v2; b = v0
        case 1: r = v1; g = vv; b = v0
        case 2: r = v0; g = vv; b = v2
        case 3: r = v0; g = v1; b = vv
        case 4: r = v2; g = v0; b = vv
        case 5: r = vv; g = v0; b = v1
        default: break
        }
        return Rgb(r, g, b) // converts normalized floats back to UInt8s
    }
}
