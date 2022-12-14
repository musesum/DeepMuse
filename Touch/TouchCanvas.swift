//  Created by warren on 2/5/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import UIKit
import MuMenu // PeersController
import Tr3 // digits

class TouchCanvas {

    internal var touch0 = [TouchCanvasItem]()
    internal var touch1 = [TouchCanvasItem]()
    internal var touchItems: [[TouchCanvasItem]] // double buffer index == 0 or 1
    internal var lastItem: TouchCanvasItem? // allow last touch to repeat until isDone
    internal var quadXYR = QuadXYR()
    internal var indexNow = 0
    internal var isDone = false
    internal var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch

    private var isRemote: Bool

    init(isRemote: Bool) {
        touchItems = [touch0,touch1]
        self.isRemote = isRemote
    }
    func addTouchCanvasItem(_ key: Int,
                      _ touch: UITouch) {

        let force = touch.force
        let radius = touch.majorRadius
        let nextXY = touch.preciseLocation(in: nil)
        let phase = touch.phase
        let azimuth = touch.azimuthAngle(in: nil)
        let altitude = touch.altitudeAngle

        let item = makeTouchItem(key, force, radius, nextXY, phase, azimuth, altitude)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(item)
            PeersController.shared.sendMessage(data, viaStream: true)
        } catch {
            print(error)
        }
    }

    func makeTouchItem(_ key     : Int,
                       _ force   : CGFloat,
                       _ radius  : CGFloat,
                       _ nextXY  : CGPoint,
                       _ phase   : UITouch.Phase,
                       _ azimuth : CGFloat,
                       _ altitude: CGFloat) -> TouchCanvasItem {

        let alti = (.pi/2 - altitude) / .pi/2
        let azim = CGVector(dx: -sin(azimuth) * alti, dy: cos(azimuth) * alti)
        var force = Float(force)
        var radius = Float(radius)
        
        if let lastItem {

            let forceFilter = Float(0.90)
            force = (lastItem.force * forceFilter) + (force * (1-forceFilter))

            let radiusFilter = Float(0.95)
            radius = (lastItem.radius * radiusFilter) + (radius * (1-radiusFilter))
            //print(String(format: "* %.3f -> %.3f", lastItem.force, force))
        } else {
            force = 0 // bug: always begins at 0.5
        }
        let item = TouchCanvasItem(key, nextXY, radius, force, azim, phase)
        touchItems[indexNow].append(item)
        return item
    }
    func addCanvasItem(_ item: TouchCanvasItem) {
        touchItems[indexNow].append(item)
    }
    /// For each finger, iterate intermediate points,
    /// with closure to drawing routine
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
            // finger is stationary repeat last movement
            flushItem(lastItem)
        }
        touchItems[indexFlush].removeAll()

        func flushItem(_ item: TouchCanvasItem) {

            let radius = SkyVC.shared.touchDraw.update(item)
            let p = CGPoint(x: CGFloat(item.nextX), y: CGFloat(item.nextY))
            isDone = (item.phase == UITouch.Phase.ended    .rawValue ||
                      item.phase == UITouch.Phase.cancelled.rawValue )
            quadXYR.addXYR(p, radius, isDone)
            quadXYR.iterate12(drawPoint)
        }
    }

}
