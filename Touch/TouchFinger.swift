//  Created by warren on 2/5/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import UIKit
import MuCubic

class TouchFinger {

    var touchItems: [[TouchItem]] = [[TouchItem](), [TouchItem]()] // double buffer index == 0 or 1
    var lastItem: TouchItem? // allow last touch to repeat until isDone
    var quadXYR = QuadXYR()
    var indexNow = 0
    var isDone = false
    var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch

    func cacheTouchItem(_ touch: UITouch,
                        _ event: UIEvent?) {

        let nextItem = makeTouchItem(touch, event)
        touchItems[indexNow].append(nextItem)
    }
    func makeTouchItem(_ touch: UITouch,
                       _ event: UIEvent?) -> TouchItem {

        let key = String(format: "%p", touch)

        var force = touch.force
        var radius = touch.majorRadius
        let nextXY = touch.preciseLocation(in: nil)
        let prevXY = touch.precisePreviousLocation(in: nil)
        let phase = touch.phase
        let time = event?.timestamp ?? Date().timeIntervalSince1970
        let angle = touch.azimuthAngle(in: nil)
        let alti = (.pi/2 - touch.altitudeAngle) / .pi/2
        let azim = CGVector(dx: -sin(angle) * alti, dy: cos(angle) * alti)

        if let lastItem {

            let forceFilter = 0.90
            force = (lastItem.force * forceFilter) + (force * (1-forceFilter))

            let radiusFilter = CGFloat(0.95)
            radius = (lastItem.radius * radiusFilter) + (radius * (1-radiusFilter))
            //print(String(format: "* %.3f -> %.3f", lastItem.force, force))
        } else {
            force = 0 // bug: always begins at 0.5
        }
        let item = TouchItem(key, time, prevXY, nextXY, radius, force, azim, phase)
        return item

    }
    /// For each finger, iterate intermediate points, with closure to drawing routine
    ///
    func flushCacheBuf(_ closure: @escaping (CGPoint, CGFloat)->())  {

        let indexPrev = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1 // switch double buffer

        // there is new movement of finger
        let count = touchItems[indexPrev].count
        if count > 0 {
            for item in touchItems[indexPrev] {

                flushItem(item)
                // last last movement for repeat
                lastItem = touchItems[indexPrev].last
            }
        }
        // finger is stationary
        else if TouchView.shared.touchRepeat {
            // so maybe repeat last movement
            flushItem(lastItem)
        }
        touchItems[indexPrev].removeAll()

        func flushItem(_ item: TouchItem?) {
            
            if let item {
                let radius = TouchDraw.shared.update(item)
                let p = CGPoint(x: item.next.x, y: item.next.y)
                isDone = item.phase == .ended || item.phase == .cancelled
                quadXYR.addXYR(p, radius, isDone)
                quadXYR.iterate12(closure)
            }
        }
    }

}
