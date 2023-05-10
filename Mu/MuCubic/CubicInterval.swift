//  Created by warren on 7/26/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import QuartzCore

public struct MuCubic {

    var cubic0 = CubicXY()  // first third of animation time interval
    var cubic1 = CubicXY()  // second third of animation time interval
    var cubic2 = CubicXY()  // last third of animation time interval

    public init () {

        // these interval points were created for a dock,
        // which has a somewhat constant horizontal speed animation
        // with a faster vertical acceleration that overshoots
        // and then falls back to target
        let p0 = CGPoint(x: 0.0, y: 0.0) // start at zero
        let p1 = CGPoint(x: 0.3, y: 0.5) // x is linear, y acclerates faster
        let p2 = CGPoint(x: 0.7, y: 1.2) // x is linear, y overshoots target
        let p3 = CGPoint(x: 1.0, y: 1.0) // x finishes, y settles back to target

        cubic0.makeCoeficients(Point4(p0, p0, p1, p2))
        cubic1.makeCoeficients(Point4(p0, p1, p2, p3))
        cubic2.makeCoeficients(Point4(p1, p2, p3, p3))
    }

    /// this was timePoint, renamed to intervalPoint
    public func point(for interval: CGFloat) -> CGPoint {

        let inter = min(1.0, interval)

        if      inter < 1/3 { return cubic0.getInterPoint((inter      ) * 3) }
        else if inter < 2/3 { return cubic1.getInterPoint((inter - 1/3) * 3) }
        else                { return cubic2.getInterPoint((inter - 2/3) * 3) }
    }
}

