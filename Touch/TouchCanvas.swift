//  Created by warren on 2/5/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import UIKit
import MuCubic

class TouchCanvas {

    internal var touch0 = [TouchCanvasItem]()
    internal var touch1 = [TouchCanvasItem]()
    internal var touchItems: [[TouchCanvasItem]] // double buffer index == 0 or 1
    internal var lastItem: TouchCanvasItem? // allow last touch to repeat until isDone
    internal var quadXYR = QuadXYR()
    internal var indexNow = 0
    internal var isDone = false
    internal var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch

    init() {
        touchItems = [touch0,touch1]
    }

    func addTouchItem(_ touch: UITouch,
                      _ event: UIEvent?) {

        guard let time = event?.timestamp else { return }
        var force = touch.force
        var radius = touch.majorRadius
        let nextXY = touch.preciseLocation(in: nil)
        let prevXY = touch.precisePreviousLocation(in: nil)
        let phase = touch.phase
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
        let item = TouchCanvasItem(time, prevXY, nextXY, radius, force, azim, phase)
        touchItems[indexNow].append(item)
    }
    func addMidiCanvasItem(_ item: TouchCanvasItem) {
        touchItems[indexNow].append(item)
    }
    /// For each finger,b iterate intermediate points, with closure to drawing routine
    ///
    func flushTouches(_ drawPoint: @escaping (CGPoint, CGFloat)->())  {

        let indexFlush = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1 // switch double buffer

        // there is new movement of finger
        let count = touchItems[indexFlush].count
        if count > 0 {
            for item in touchItems[indexFlush] {

                flushItem(item)
                // last last movement for repeat
                lastItem = touchItems[indexFlush].last
            }
        } else if TouchView.shared.touchRepeat, let lastItem {
            // finger is stationary
            // so repeat last movement
            flushItem(lastItem)
        }
        touchItems[indexFlush].removeAll()

        func flushItem(_ item: TouchCanvasItem) {

            let radius = SkyVC.shared.touchDraw.update(item)
            let p = CGPoint(x: item.next.x, y: item.next.y)
            isDone = item.phase == .ended || item.phase == .cancelled
            quadXYR.addXYR(p, radius, isDone)
            quadXYR.iterate12(drawPoint)
        }
    }

}
