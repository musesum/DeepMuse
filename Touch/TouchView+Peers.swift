//  Created by warren on 12/11/22.

import Foundation
import MuMenu // TouchMenuItem

extension TouchView: PeersControllerDelegate {

    public func didChange() {
    }

    public func received(data: Data,
                         viaStream: Bool) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(TouchCanvasItem.self, from: data) {
            TouchCanvas.remoteItem(item)
            return
        }
        if let item = try? decoder.decode(TouchMenuItem.self, from: data) {
            TouchMenu.remoteItem(item)
            return
        }
    }

}
