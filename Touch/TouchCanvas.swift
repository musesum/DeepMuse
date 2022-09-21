//  Created by warren on 2/5/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import UIKit
import MuCubic
import MuMenu


class TouchMenu {
    internal var touch0 = [TouchMenuItem]()
    internal var touch1 = [TouchMenuItem]()
    internal var touchItems: [[TouchMenuItem]]
    internal var indexNow = 0
    internal let touchVm: MuTouchVm

    init(_ touchVm: MuTouchVm) {
        self.touchVm = touchVm
        touchItems = [touch0,touch1]
    }
    func addTouchItem(_ touch: UITouch,
                      _ event: UIEvent?) {

        guard let time = event?.timestamp else { return }
        let isDone = touch.phase == .ended || touch.phase == .cancelled
        let nextXY = isDone ? .zero : touch.location(in: nil)
        let menuItem = TouchMenuItem(time, nextXY, touch.phase)
        touchItems[indexNow].append(menuItem)
    }

    func flushTouches() -> Bool {

        let indexFlush = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1 // switch double buffer
                                // there is new movement of finger
        var isDone = false
        let count = touchItems[indexFlush].count
        if count > 0 {

            for item in touchItems[indexFlush] {
                isDone = (item.phase == .ended ||
                          item.phase == .cancelled)

                touchVm.touchMenuUpdate(item.next)
            }
        }
        touchItems[indexFlush].removeAll()
        return isDone
    }
}

class TouchCanvas {

    internal var touch0 = [TouchDrawItem]()
    internal var touch1 = [TouchDrawItem]()
    internal var touchItems: [[TouchDrawItem]] // double buffer index == 0 or 1
    internal var lastItem: TouchDrawItem? // allow last touch to repeat until isDone
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
        let item = TouchDrawItem(time, prevXY, nextXY, radius, force, azim, phase)
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

        func flushItem(_ item: TouchDrawItem) {

            let radius = SkyVC.shared.touchDraw.update(item)
            let p = CGPoint(x: item.next.x, y: item.next.y)
            isDone = item.phase == .ended || item.phase == .cancelled
            quadXYR.addXYR(p, radius, isDone)
            quadXYR.iterate12(drawPoint)
        }
    }

}
