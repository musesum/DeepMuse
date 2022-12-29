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
                 let nodeVm = touchMenu.touchVm.hitTest(nextXY)
                 touchMenu.addLocalItem(nodeVm, touch)
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

        let nextXY: [Double]
        if touch.phase.isDone()  {
            nextXY = [0,0]
        } else {
            let xy = touch.location(in: nil)
            nextXY = [Double(xy.x), Double(xy.y)]
        }

        let item = TouchMenuItem(
            menuKey   : touch.hash,
            cornerStr : touchVm.corner?.str() ?? "??",
            nodeType  : nodeVm?.nodeType ?? .none,
            treePath  : [],
            treeNow   : 0,
            thumb     : nextXY,
            phase     : touch.phase)

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
            touchVm.updateTouchXY(item.nextXY, item.phase)
        }
        return isDone
    }
}

extension TouchMenu {

    static func remoteItem(_ item: TouchMenuItem) {
        if let menu = menuKey[item.menuKey] {
            menu.buffer.append(item)
            return
        } else {
            for touchVm in touchVms {
                if touchVm.corner?.str() == item.cornerStr {
                    addRemoteTouch(touchVm)
                    return
                }
            }
        }
        func addRemoteTouch(_ touchVm: MuTouchVm) {
            let touchMenu = TouchMenu(touchVm, nil, isRemote: true)
            menuKey[item.menuKey] = touchMenu
            touchMenu.buffer.append(item)
            TouchMenu.bufferLoop(item.menuKey, touchMenu)
        }
    }
}
