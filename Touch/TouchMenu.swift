//  Created by warren on 9/26/22

import UIKit
import MuMenu

class TouchMenu {

    let buffer = DoubleBuffer<TouchMenuItem>()

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

    public static func beginTouch(_ touch: UITouch) -> Bool {

        let key = touch.hash
        let nextXY = touch.preciseLocation(in: nil)

        for touchVm in touchVms {
            if let (corner, nodeVm) = touchVm.hitTest(nextXY) {

                let touchMenu = TouchMenu(touchVm, isRemote: false)
                let hashPath = nodeVm.node.hashPath
                touchMenu.addTouchMenuItem(key, corner, hashPath, touch)
                menuKey[key] = touchMenu

                timerKey[key] = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    let isDone = touchMenu.buffer.flush()
                    if isDone {
                        timer.invalidate()
                        self.timerKey.removeValue(forKey: key)
                        self.menuKey.removeValue(forKey: key)
                    }
                }
                return true
            }
        }
        return false
    }

    static func updateTouch(_ touch: UITouch) -> Bool {
        let key = touch.hash
        if let touchMenu = menuKey[key] {
            // continue on menu
            let nextXY = touch.preciseLocation(in: nil)
            for touchVm in touchVms {
                if let (corner,nodeVm) = touchVm.hitTest(nextXY) {
                    touchMenu.addTouchMenuItem(key, corner, nodeVm.node.hashPath, touch)
                }
            }
            return true
        }
        return false
    }
    func addTouchMenuItem(_ menuKey: Int,
                          _ corner: MuCorner,
                          _ hashPath: [Int],
                          _ touch: UITouch) {

        let isDone = touch.phase == .ended || touch.phase == .cancelled
        let nextXY = isDone ? .zero : touch.location(in: nil)
        let cornerStr = corner.abbreviation()
        let item = TouchMenuItem(menuKey, cornerStr, hashPath, nextXY, touch.phase)

        buffer.append(item)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(item)
            PeersController.shared.sendMessage(data, viaStream: true)
        } catch {
            print(error)
        }
    }

    func addMenuItem(_ item: TouchMenuItem) {
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
            touchVm.touchMenuUpdate(item.nextXY)
        }
        return isDone
    }
}
extension TouchMenu {

    static func updateItem(_ item: TouchMenuItem) {

        if let menu = menuKey[item.menuKey] {
            menu.addMenuItem(item)
        } else {
            let menuVm = touchVms.first! //????
            let menu = TouchMenu(menuVm, isRemote: true)
            menuKey[item.menuKey] = menu
            menu.addMenuItem(item)
            _ = menu.buffer.flush()
        }
    }
}
