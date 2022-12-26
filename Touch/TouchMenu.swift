//  Created by warren on 9/26/22

import UIKit
import MuMenu

class TouchMenu {
    static var touchVms = [MuTouchVm]()
    static var menuKey = [Int: TouchMenu]()
    static var timerKey = [Int: Timer]()

    private let buffer = DoubleBuffer<TouchMenuItem>()
    private let touchVm: MuTouchVm
    private let isRemote: Bool
    private let nodeVm: MuNodeVm?


    init(_ touchVm: MuTouchVm,
         _ nodeVm: MuNodeVm?,
         isRemote: Bool) {
        self.touchVm = touchVm
        self.nodeVm = nodeVm
        self.isRemote = isRemote
        buffer.flusher = self
    }

    static func beginTouch(_ touch: UITouch) -> Bool {

        let nextXY = touch.preciseLocation(in: nil)

        for touchVm in touchVms {
            if let nodeVm = touchVm.hitTest(nextXY) {

                let touchMenu = TouchMenu(touchVm, nodeVm, isRemote: false)
                touchMenu.addLocalItem(nodeVm, touch)
                let key = touch.hash
                menuKey[key] = touchMenu
                bufferLoop(key, touchMenu)
                return true
            }
        }
        return false
    }

    static func updateTouch(_ touch: UITouch) -> Bool {
        let key = touch.hash
        let nextXY = touch.preciseLocation(in: nil)

        if let touchMenu = menuKey[key] {
            if touchMenu.nodeVm?.nodeType.isLeaf ?? false {
                touchMenu.addLocalItem(touchMenu.nodeVm, touch)
            } else {
                if let nodeVm = touchMenu.touchVm.hitTest(nextXY) {
                    touchMenu.addLocalItem(nodeVm, touch)
                }
            }
            return true
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
    func addLocalItem(_ nodeVm: MuNodeVm?,
                      _ touch: UITouch) {

        let menuKey = touch.hash
        let cornerStr = touchVm.corner?.abbreviation() ?? "??"
        let isDone = touch.phase == .ended || touch.phase == .cancelled
        let nextXY = isDone ? .zero : touch.location(in: nil)
        let nodeType = nodeVm?.nodeType ?? .none
        let item = TouchMenuItem(menuKey, cornerStr, nodeType, [], 0, nextXY, touch.phase)

        buffer.append(item)
    }
}

extension TouchMenu: BufferFlushDelegate {

    typealias Item = TouchMenuItem

    func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! TouchMenuItem
        let isDone = item.isDone()
        if isRemote {
            touchVm.gotoRemoteItem(item)
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

        } else {
            for touchVm in touchVms {
                if touchVm.corner?.abbreviation() == item.cornerStr {
                    addRemoteTouch(touchVm)
                    return
                }
            }
        }
        if let touchVm = touchVms.first {
            addRemoteTouch(touchVm)
        }
        func addRemoteTouch(_ touchVm: MuTouchVm) {
            let touchMenu = TouchMenu(touchVm, nil, isRemote: true)
            menuKey[item.menuKey] = touchMenu
            touchMenu.buffer.append(item)
            TouchMenu.bufferLoop(item.menuKey, touchMenu)
        }
    }
}
