//  Created by warren on 12/15/22.


import SwiftUI

extension TouchView { // +Canvas

    func assignFingerCanvas(_ key: Int,
                            _ touch: UITouch) -> Bool {

        let touchCanvas = TouchCanvas(isRemote: false)
        canvasKey[key] = touchCanvas
        touchCanvas.addTouchCanvasItem(key, touch)
        return true
    }

    func addCanvasItem(_ item: TouchCanvasItem,
                       isRemote: Bool) {
        let key = item.key
        if canvasKey[key] == nil {
            canvasKey[key] = TouchCanvas(isRemote: isRemote)
        }
        canvasKey[key]?.buffer.append(item)
    }

    func drawPoint(_ point: CGPoint, _ radius: CGFloat) {
        for (key, canvas) in canvasKey {
            canvas.flushTouches()
            if canvas.isDone {
                canvasKey.removeValue(forKey: key)
            }
        }
    }

    /// for each finger, iterate intermediate points, with closure
    func flushTouchCanvas() {

        for (key, canvas) in canvasKey {
            canvas.flushTouches()
            if canvas.isDone {
                canvasKey.removeValue(forKey: key)
            }
        }
    }
    
}
