//  created by musesum on 4/20/23.

import SwiftUI
import MuMenu
import MuMetal

open class SkyTouchView: TouchesView {
    
    var safeBounds: CGRect { frame.pad(-4) }
    var touchBeganFromEdge = [Int: Bool]()
    
    func willBeginFromEdge(_ touch: UITouch) -> Bool {
        let touchXY = touch.preciseLocation(in: nil)
        let fromEdge = safeBounds.contains(touchXY) ? false : true
        touchBeganFromEdge[touch.hash] = fromEdge
        return fromEdge
    }
    func beganFromEdge(_ touch: UITouch) -> Bool {
        if let fromEdge = touchBeganFromEdge[touch.hash] {
            if touch.phase.isDone() {
                touchBeganFromEdge.removeValue(forKey: touch.hash)
            }
            return fromEdge
        }
        return false
    }

    /// When starting new touch, assign finger to either Menu or Canvas.
    ///
    ///   - note: allow shifting menu, starting from offscreen
    ///
    override open func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            //print("\(touch.phase.rawValue)",terminator: "")
            if      TouchMenuLocal.beginTouch(touch) { }
            else if willBeginFromEdge(touch) {}
            else if TouchCanvas.shared.beginTouch(touch) { }
        }
    }

    /// Continue dispatching finger to canvas or menu
    override open func updateTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            //print("\(touch.phase.rawValue)⃝",terminator: "")
            if      beganFromEdge(touch) {}
            else if TouchCanvas.shared.updateTouch(touch) { }
            else if TouchMenuLocal.updateTouch(touch) { }
            else { print("*** unknown touch \(touch.hash)") }
        }
    }
}
