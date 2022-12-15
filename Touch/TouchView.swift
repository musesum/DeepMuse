
import SwiftUI
import MuMenu
import Tr3
import MultipeerConnectivity


class TouchView: UIView, UIGestureRecognizerDelegate {
    static let shared = TouchView()

    private var touchRepeat˚: Tr3?
    var touchRepeat = false /// repeat touch, even when not moving finger

    var canvasKey = [Int: TouchCanvas]()
    public var menuKey = [Int: TouchMenu]()
    var timerKey = [Int: Timer]()
    var touchVms = [MuTouchVm]()

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
        
        touchRepeat˚ = SkyTr3.shared.root.bindPath("shader.model.pipe.draw") { tr3, _ in
            if let p = tr3.CGPointVal() {
                self.touchRepeat = (abs(p.x - 0.5) > 0.001 ||
                                    abs(p.y - 0.5) > 0.001)
            }
        }
    }
    deinit {
        PeersController.shared.remove(peersDelegate: self)
    }


    /// When starting new touch, assign finger to either Menu or Canvas.
    func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {

            if touch.phase != .began {
                print("*** beginTouches unexpected non .began")
                updateTouches(touches)
            }
            let key = touch.hash

            if !assignFingerMenu(key, touch) {
                assignFingerCanvas(key, touch)
            }
        }
    }

  
    /// Continue dispatching finger to canvas or menu
    ///
    func updateTouches(_ touches: Set<UITouch>) {

        for touch in touches {

            let key = touch.hash

            if let touchCanvas = canvasKey[key] {
                // continue on canvas
                touchCanvas.addTouchCanvasItem(key, touch)

            }  else if let touchMenu = menuKey[key] {
                // continue on menu
                let nextXY = touch.preciseLocation(in: nil)
                for touchVm in touchVms {
                    if let (corner,nodeVm) = touchVm.hitTest(nextXY) {

                        touchMenu.addTouchMenuItem(key, corner, nodeVm.node.hashPath, touch)
                    }
                }
            } else {
                print("*** unknown touch \(key)")
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
}
