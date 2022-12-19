//  Created by warren on 9/26/22

import UIKit
import MuMenu

class TouchMenu {

    private let buffer = DoubleBuffer<TouchMenuItem>()
    private let touchVm: MuTouchVm
    private let isRemote: Bool

    static var touchVms = [MuTouchVm]()
    static var menuKey = [Int: TouchMenu]()
    static var timerKey = [Int: Timer]()

    init(_ touchVm: MuTouchVm,
         isRemote: Bool) {

        self.touchVm = touchVm
        self.isRemote = isRemote
        buffer.flusher = self
    }

    static func beginTouch(_ touch: UITouch) -> Bool {

        let nextXY = touch.preciseLocation(in: nil)

        for touchVm in touchVms {
            if let (corner, nodeVm) = touchVm.hitTest(nextXY) {

                let touchMenu = TouchMenu(touchVm, isRemote: false)
                touchMenu.addItem(corner, nodeVm, touch)
                let key = touch.hash
                menuKey[key] = touchMenu
                bufferLoop(key, touchMenu)
                return true
            }
        }
        return false
    }

    static func bufferLoop(_ key: Int,
                           _ touchMenu: TouchMenu) {

        timerKey[key] = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let isDone = touchMenu.buffer.flush()
            if isDone {
                timer.invalidate()
                self.timerKey.removeValue(forKey: key)
                self.menuKey.removeValue(forKey: key)
            }
        }
    }

    static func updateTouch(_ touch: UITouch) -> Bool {
        let key = touch.hash
        if let touchMenu = menuKey[key] {
            let nextXY = touch.preciseLocation(in: nil)
            for touchVm in touchVms {
                if let (corner,nodeVm) = touchVm.hitTest(nextXY) {
                    touchMenu.addItem(corner, nodeVm, touch)
                }
            }
            return true
        }
        return false
    }

    // MARK: - instances
    func addItem(_ corner: MuCorner,
                 _ nodeVm: MuNodeVm,
                 _ touch: UITouch) {

        let menuKey = touch.hash
        let hashPath = nodeVm.node.hashPath
        let cornerStr = corner.abbreviation()

        let isDone = touch.phase == .ended || touch.phase == .cancelled
        let nextXY = isDone ? .zero : touch.location(in: nil)
        let nodeType = nodeVm.nodeType
        let item = TouchMenuItem(menuKey, cornerStr, nodeType, hashPath, nextXY, touch.phase)

        buffer.append(item)
    }
}
extension TouchMenu: BufferFlushDelegate {

    typealias Item = TouchMenuItem

    func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! TouchMenuItem
        let isDone = item.isDone()
        if isRemote {
            touchVm.gotoMenuItem(item)
        } else {
            let nextXY = isDone ? .zero : item.nextXY
            touchVm.updateTouchXY(nextXY)
        }
        return isDone
    }
}
extension TouchMenu {

    static func remoteItem(_ item: TouchMenuItem) {
        if let menu = menuKey[item.menuKey] {
            menu.buffer.append(item)

        } else if let touchVm = touchVms.first {
            //TODO: test all touchVms matching corner?

            let touchMenu = TouchMenu(touchVm, isRemote: true)
            menuKey[item.menuKey] = touchMenu
            touchMenu.buffer.append(item)
            TouchMenu.bufferLoop(item.menuKey, touchMenu)
        }
    }
}
