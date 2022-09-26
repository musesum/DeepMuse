//  Created by warren on 9/26/22.

import UIKit

struct TouchMenuItem {

    internal var time: TimeInterval
    internal let next: CGPoint
    internal let phase: UITouch.Phase

    init(_ time: TimeInterval,
         _ next: CGPoint,
         _ phase: UITouch.Phase) {

        self.time = time
        self.next = next
        self.phase = phase
    }

}

