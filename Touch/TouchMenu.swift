//  Created by warren on 9/26/22

import UIKit
import MuMenu



class TouchMenu {

    let buffer = DoubleBuffer<TouchMenuItem>()

    private let touchVm: MuTouchVm
    private let isRemote: Bool

    init(_ touchVm: MuTouchVm,
         isRemote: Bool) {


        self.touchVm = touchVm
        self.isRemote = isRemote
        buffer.flusher = self
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
