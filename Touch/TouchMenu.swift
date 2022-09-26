//  Created by warren on 9/26/22

import UIKit
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
