//  Created by warren on 7/30/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation

public struct Rgb {

    public var r: Float // 0...1
    public var g: Float // 0...1
    public var b: Float // 0...1
    public var a: Float // = 1

    public init(_ r: Float, _ g: Float, _ b: Float, _ a: Float = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// return 0..<360
    func hsv() -> Hsv {

        let Min = min(r, min(g, b))
        let Max = max(r, max(g, b))
        if  Max == 0 { return Hsv(0, 0, 0) }

        let delta = Max-Min
        let ss = delta/Max
        var hh = Float(0)
        let vv = Max

        if      r == Max { hh =       ( g - b ) / delta } // between yellow & magenta
        else if g == Max { hh = 2.0 + ( b - r ) / delta } // between cyan & yellow
        else             { hh = 4.0 + ( r - g ) / delta } // between magenta & cyan
        hh /= 60                // degrees
        if hh < 0 { hh += 1 }
        return Hsv(hh, ss, vv)
    }
}
