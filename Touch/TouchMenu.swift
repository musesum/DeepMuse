//  Created by warren on 9/26/22

import UIKit
import MuMenu

class TouchMenu {

    // double buffer
   private var touch0 = [TouchMenuItem]()
   private var touch1 = [TouchMenuItem]()
   private var touchItems: [[TouchMenuItem]]
   private var indexNow = 0

    private let touchVm: MuTouchVm
    private let isRemote: Bool

    init(_ touchVm: MuTouchVm,
         isRemote: Bool) {

        self.touchVm = touchVm
        self.isRemote = isRemote
        touchItems = [touch0,touch1]
    }

    func addTouchMenuItem(_ menuKey: Int,
                          _ corner: MuCorner,
                          _ hashPath: [Int],
                          _ touch: UITouch) {

        let isDone = touch.phase == .ended || touch.phase == .cancelled
        let nextXY = isDone ? .zero : touch.location(in: nil)
        let cornerStr = corner.abbreviation()
        let item = TouchMenuItem(menuKey, cornerStr, hashPath, nextXY, touch.phase)
        touchItems[indexNow].append(item)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(item)
            PeersController.shared.sendMessage(data, viaStream: true)
        } catch {
            print(error)
        }
    }

    func addMenuItem(_ item: TouchMenuItem) {
        touchItems[indexNow].append(item)
    }
    func flushTouches() -> Bool {

        let indexFlush = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1 // switch double buffer
                                // there is new movement of finger
        var isDone = false
        let count = touchItems[indexFlush].count
        if count > 0 {

            for menuItem in touchItems[indexFlush] {

                isDone = (menuItem.phase == UITouch.Phase.ended.rawValue ||
                          menuItem.phase == UITouch.Phase.cancelled.rawValue)

                if isRemote {

                    touchVm.gotoMenuItem(menuItem) //???

                } else {
                    let nextXY = CGPoint(x: CGFloat(menuItem.nextX),
                                         y: CGFloat(menuItem.nextY))

                    touchVm.touchMenuUpdate(nextXY)
                }
            }
        }
        touchItems[indexFlush].removeAll()
        return isDone
    }
}
