
import UIKit
import SwiftUI
import MuMenu

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
    var touchRepeat = false /// repeat touch, even when not moving finger
    var fingerKey = [String: TouchFinger]()
    var touchVmKey = [String: MuTouchVm]()
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
    }

    /// for each finger, iterate intermediate points, with closure
    /// Previous version used to draw directly into buf, but now passes a closure
    func flushFingersBuf(_ draw: @escaping (CGPoint, CGFloat)->(),
                         _ done: @escaping ()->()) {

        for (key, finger) in fingerKey {
            finger.flushCacheBuf(draw)
            if finger.isDone {
                fingerKey.removeValue(forKey: key)
            }
        }
    }


    /// Add new touches to be drawn in the NextFrame, above.
    ///
    /// During the lifecycle of a touch, the memory address of
    /// a specific touch remains the same, so use that as a key
    /// into a dictionary of fingerNext to retrieve an
    /// array of events.
    ///
    /// If this is the first time for a new finger
    /// then create a new array and add it dictionary of fingerNext.
    ///
    func updateTouches(_ touches: Set<UITouch>,
                       _ event: UIEvent?) {
        for touch in touches {
            let key = String(format: "%p", touch)
            let isDone = [.ended, .cancelled].contains(touch.phase)

            if let finger = fingerKey[key] {
                // continue on canvas
                finger.cacheTouchItem(touch, event)

            } else if let touchVm = touchVmKey[key] {
                // continue on menu
                if isDone {
                    // update menu with .zero, which is interpreted as done
                    self.touchVmKey.removeValue(forKey: key)
                    return touchVm.touchMenuUpdate(.zero)

                } else {
                    /// update menu with location
                    let nextXY = touch.preciseLocation(in: nil)
                    return touchVm.touchMenuUpdate(nextXY)
                }
            } else {
                // beginning on Menu
                if touch.phase == .began {
                    let nextXY = touch.preciseLocation(in: nil)
                    for touchVm in touchVms {

                        if touchVm.hitTest(nextXY) {
                            touchVmKey[key] = touchVm
                            let nextXY = touch.preciseLocation(in: nil)
                            return touchVm.touchMenuUpdate(nextXY)
                        }
                    }
                }
                // beginning on canvas
                let finger = TouchFinger()
                fingerKey[key] = finger
                finger.cacheTouchItem(touch, event)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }

}
