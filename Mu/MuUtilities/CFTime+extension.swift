//  Created by warren on 8/7/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import QuartzCore

public var CFAbsoluteStartTime = CFAbsoluteTime(0)
public let LoopTime = CFTimeInterval(1.0 / 60.0)

public func Looper (_ duration: CFAbsoluteTime,
                    _ interval: CFAbsoluteTime,
                    _ looping: @escaping ((CGFloat)->()),
                    _ completion: (()->())? = nil) -> Timer? {

    let startTime = CFAbsoluteTimeGetCurrent()
    var timer: Timer?

    func loopNext() {
        let deltaTime = CFAbsoluteTimeGetCurrent() - startTime
        let remainTime = duration - deltaTime
        let factor = remainTime <= 0 ? 1 : min(1.0, interval / remainTime)

        if factor == 0 || remainTime <= 0 {
            timer?.invalidate()
            completion?()
        }
        else {
            looping(CGFloat(factor))
        }
    }
    //print("deltaTime:\(deltaTime) remain:\(remainTime) factor:\(factor)")

    timer = Timer.scheduledTimer(withTimeInterval: LoopTime, repeats: true)  {_ in
        loopNext()
    }

    return timer
}
