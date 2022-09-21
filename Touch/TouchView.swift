
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
                            ///
    var canvasKey = [String: TouchCanvas]()
    var menuKey = [String: TouchMenu]()
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

    /// for each finger, iterate intermediate points, with closure
    /// Previous version used to draw directly into buf, but now passes a closure
    func flushTouchMenu() {

        for (key, finger) in menuKey {
            let isDone = finger.flushTouches()
            if isDone {
                canvasKey.removeValue(forKey: key)
            }
        }
    }


    func beginTouches(_ touches: Set<UITouch>,
                      _ event: UIEvent?) {

        for touch in touches {

            if touch.phase != .began {
                print("*** beginTouches unexpected non .began")
                updateTouches(touches, event)
            }
            let key = String(format: "%p", touch)
            let nextXY = touch.preciseLocation(in: nil)
            if !addTouchVm() {
                let touchCanvas = TouchCanvas()
                canvasKey[key] = touchCanvas
                touchCanvas.addTouchItem(touch, event)
            }

            func addTouchVm() -> Bool {
                for touchVm in touchVms {
                    if touchVm.hitTest(nextXY) {
                        let touchMenu = TouchMenu(touchVm)
                        menuKey[key] = touchMenu
                        touchMenu.addTouchItem(touch, event)
                        return true
                        //?? Task.async { touchVm.touchMenuUpdate(nextXy) }z
                    }
                }
                return false
            }
        }
    }
    func updateTouches(_ touches: Set<UITouch>,
                       _ event: UIEvent?) {

        for touch in touches {
            let key = String(format: "%p", touch)

            if let canvas = canvasKey[key] {
                // continue on canvas
                canvas.addTouchItem(touch, event)
            }  else if let menu = menuKey[key] {
                // continue on canvas
                menu.addTouchItem(touch, event)
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
