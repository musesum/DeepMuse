
import UIKit
import SwiftUI
import MuMenu
import Tr3

struct TouchViewRepresentable: UIViewRepresentable {
    
    typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    var touchVms: [MuTouchVm]
    var touchView = TouchView.shared

    init(_ touchVms: [MuTouchVm]) {
        self.touchVms = touchVms
        touchView.touchVms.append(contentsOf: touchVms)
    }
    public func makeUIView(context: Context) -> TouchView {
        return touchView
    }
    public func updateUIView(_ uiView: TouchView, context: Context) {
        //print("updateUIView", terminator: " ")
    }
}

class TouchView: UIView, UIGestureRecognizerDelegate {
    static let shared = TouchView()

    private var touchRepeat˚: Tr3?
    var touchRepeat = false /// repeat touch, even when not moving finger
    var canvasKey = [String: TouchCanvas]()
    var menuKey = [String: TouchMenu]()
    var timerKey = [String: Timer]()
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
        
        touchRepeat˚ = SkyTr3.shared.root.bindPath("shader.model.pipe.draw") { tr3, _ in
            if let p = tr3.CGPointVal() {
                self.touchRepeat = (abs(p.x - 0.5) > 0.001 ||
                                    abs(p.y - 0.5) > 0.001)
            }
        }
    }

    /// for each finger, iterate intermediate points, with closure
    /// Previous version used to draw directly into buf, but now passes a closure
    func flushTouchCanvas(_ drawPoint: @escaping (CGPoint, CGFloat)->()) {

        for (key, finger) in canvasKey {
            finger.flushTouches(drawPoint)
            if finger.isDone {
                canvasKey.removeValue(forKey: key)
            }
        }
    }

    /// When starting new touch, assign finger
    /// to either Menu or Canvas.
    ///
    func beginTouches(_ touches: Set<UITouch>,
                      _ event: UIEvent?) {

        for touch in touches {

            if touch.phase != .began {
                print("*** beginTouches unexpected non .began")
                updateTouches(touches, event)
            }
            let key = String(format: "%p", touch)
            let nextXY = touch.preciseLocation(in: nil)
            if !assignFingerMenu() {
                assignFingerCanvas()
            }
            /// if touching menu, then assign finger
            func assignFingerMenu() -> Bool {
                for touchVm in touchVms {
                    if touchVm.hitTest(nextXY) {
                        addTouchVm(touchVm)
                        return true
                    }
                }
                return false
            }
            /// Assign this finger to menu.
            ///
            /// This loops on an internal 1/100 sec timer.
            /// It's decoupled from displayLink, which may
            /// vary frame rate between 0 to 120 fps
            ///
            func addTouchVm(_ touchVm: MuTouchVm) {
                let touchMenu = TouchMenu(touchVm)
                touchMenu.addTouchItem(touch, event)
                menuKey[key] = touchMenu
                timerKey[key] = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    let isDone = touchMenu.flushTouches()
                    if isDone {
                        timer.invalidate()
                        self.timerKey.removeValue(forKey: key)
                        self.menuKey.removeValue(forKey: key)
                    }
                }
            }
            /// Assign this finger to canvas.
            ///
            /// No internal timer loop as canvasTouches are
            /// called by display link to allow update on texture
            /// without blocking -- may need need to optimise for sure
            ///
            func assignFingerCanvas() {
                let touchCanvas = TouchCanvas()
                canvasKey[key] = touchCanvas
                touchCanvas.addTouchItem(touch, event)
            }
        }
    }

    /// Continue dispatching finger to canvas or menu
    ///
    func updateTouches(_ touches: Set<UITouch>,
                       _ event: UIEvent?) {

        for touch in touches {
            let key = String(format: "%p", touch)

            if let touchCanvas = canvasKey[key] {
                // continue on canvas
                touchCanvas.addTouchItem(touch, event)

            }  else if let touchMenu = menuKey[key] {
                // continue on menu
                touchMenu.addTouchItem(touch, event)

            } else {
                print("*** unknown touch \(key)")
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches, event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }

}
