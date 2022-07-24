
//
//  SkyDraw
//  Sky
//
//  Created by warren on 2/5/19.
//  CCopyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import UIKit
import MuCubic

class TouchFinger: NSObject {

    var touchItems: [[TouchItem]] = [[TouchItem](), [TouchItem]()] // double buffer index == 0 or 1
    var lastItem: TouchItem? // allow last touch to repeat until isDone
    var quadXYR = QuadXYR()
    var touchNext = 0
    var isDone = false

    func cacheTouchItem(_ nextItem: TouchItem?) {
        if let nextItem = nextItem {
            if let lastItem = lastItem
            //lastItem.radius > 0, lastItem.force > 0,
            //nextItem.radius > 0, nextItem.force == 0
            {
                let filter = CGFloat(0.5)
                let force = (lastItem.force * filter) + (nextItem.force * (1-filter))
                //print(String(format: "* %.3f -> %.3f", lastItem.force, force))
                nextItem.force = force

            }
            touchItems[touchNext].append(nextItem)
        }
    }

    /// For each finger, iterate intermediate points, with closure to drawing routine
    ///
    func flushCacheBuf(_ closure: @escaping (CGPoint, CGFloat)->())  {

        touchNext = touchNext ^ 1 // switch double buffer
        let touchPrev = touchNext ^ 1 // flush what used to be nextBuffer
        let skyDraw = SkyDraw.shared

        func flushItem(_ item: TouchItem?) {
            
            if let item = item {

                let radius = skyDraw.update(item)

                let p = CGPoint(x: item.next.x, y: item.next.y)

                isDone = item.phase == .ended || item.phase == .cancelled

                quadXYR.addXYR(p, radius, isDone)
                quadXYR.iterate12(closure)
            }
        }
        // begin -----------------------------

        // there is new movement of finger
        let count = touchItems[touchPrev].count
        if count > 0 {
            for item in touchItems[touchPrev] {

                flushItem(item)
                // last last movement for repeat
                lastItem = touchItems[touchPrev].last
            }
        }
        // finger is stationary
        else if SkyView.shared.touchRepeat {
            // so maybe repeat last movement
            flushItem(lastItem)
        }
        touchItems[touchPrev].removeAll()
    }
}
