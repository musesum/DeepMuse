//  Created by warren on 9/26/22

import UIKit
import MuMenu

class TouchMenu {
    static var touchVms = [MuTouchVm]()
}

class TouchMenuRemote {

    static var menuKey = [Int: TouchMenuRemote]()
    static var timerKey = [Int: Timer]()

    private let buffer = DoubleBuffer<MenuRemoteItem>()
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

    static func bufferLoop(_ key: Int,
                           _ touchMenu: TouchMenuRemote) {

        timerKey[key] = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let isDone = touchMenu.buffer.flush()
            if isDone {
                timer.invalidate()
                self.timerKey.removeValue(forKey: key)
                self.menuKey.removeValue(forKey: key)
            }
        }
    }
}

extension TouchMenuRemote: BufferFlushDelegate {

    typealias Item = MenuRemoteItem

    func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuRemoteItem
        let isDone = item.isDone()
        if isRemote {
            touchVm.gotoRemoteItem(item)
        } else {
            touchVm.updateTouchXY(item.nextXY, item.phase)
        }
        return isDone
    }
}

extension TouchMenuRemote {

    static func remoteItem(_ item: MenuRemoteItem) {
        if let menu = menuKey[item.menuKey] {
            menu.buffer.append(item)
            return
        } else {
            for touchVm in TouchMenu.touchVms {
                if touchVm.corner.rawValue == item.corner {
                    addRemoteTouch(touchVm)
                    return
                }
            }
        }
        func addRemoteTouch(_ touchVm: MuTouchVm) {
            let touchMenu = TouchMenuRemote(touchVm, nil, isRemote: true)
            menuKey[item.menuKey] = touchMenu
            touchMenu.buffer.append(item)
            TouchMenuRemote.bufferLoop(item.menuKey, touchMenu)
        }
    }
}
