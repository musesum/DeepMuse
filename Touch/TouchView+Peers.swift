//  Created by warren on 12/11/22.
import MuMenu // PeersController
import MultipeerConnectivity

extension TouchView: PeersControllerDelegate {

    public func didChange() {
    }

    public func received(data: Data,
                         viaStream: Bool) {

        let decoder = JSONDecoder()
        if getTouchCanvasItem() { return }
        if getTouchMenuItem() { return }

        /// data is a point drawing on the canvas
        func getTouchCanvasItem() -> Bool {
            if let item = try? decoder.decode(TouchCanvasItem.self, from: data) {
                if let canvas = canvasKey[item.key] {
                    canvas.addCanvasItem(item)
                } else {
                    let canvas = TouchCanvas(isRemote: true)
                    canvasKey[item.key] = canvas
                    canvas.addCanvasItem(item)
                }
                return true
            }
            return false
        }
        /// data is a menu menu node selection
        func getTouchMenuItem() -> Bool {
            if let item = try? decoder.decode(TouchMenuItem.self, from: data) {
                if let menu = menuKey[item.menuKey] {
                    menu.addMenuItem(item)
                } else {
                    let menuVm = touchVms.first! //????
                    let menu = TouchMenu(menuVm, isRemote: true)
                    menuKey[item.menuKey] = menu
                    menu.addMenuItem(item)
                    menu.flushTouches() //???
                }
                return true
            }
            return false
        }
    }

}
