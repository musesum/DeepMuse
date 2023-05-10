
import SwiftUI
import MuMenu
import MuFlo
import MultipeerConnectivity


class TouchV: UIView, UIGestureRecognizerDelegate {
    static let shared = TouchV()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(frame:.zero)
        let bounds = UIScreen.main.bounds
        let w = bounds.size.width
        let h = bounds.size.height
        frame = CGRect(x: 0, y: 0, width: w, height: h)
        isMultipleTouchEnabled = true
        PeersController.shared.peersDelegates.append(self)
    }
    deinit {
        PeersController.shared.remove(peersDelegate: self)
    }

    let safeBounds = UIScreen.main.bounds.pad(-4)
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
    func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            //print("\(touch.phase.rawValue)⃝",terminator: "")
            if      TouchMenuLocal.beginTouch(touch) { }
            else if willBeginFromEdge(touch) {}
            else if TouchCanvas.beginTouch(touch) { }
        }
    }

    /// Continue dispatching finger to canvas or menu
    func updateTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            //print("\(touch.phase.rawValue)⃝",terminator: "")
            if      beganFromEdge(touch) {}
            else if TouchCanvas.updateTouch(touch) { }
            else if TouchMenuLocal.updateTouch(touch) { }
            else { print("*** unknown touch \(touch.hash)") }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
}
