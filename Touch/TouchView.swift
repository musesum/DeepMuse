
import UIKit
import SwiftUI
import MuMenu

struct TouchRepresentable: UIViewRepresentable {
    
    typealias Context = UIViewRepresentableContext<TouchRepresentable>
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
    var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch
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

        let _ = TouchDraw.shared //TODO: circular reference?
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
        done()
    }

    // MARK: - Touches

    /// Add new touches to be drawn in the NextFrame, above.
    /// During the lifecycle of a touch, the memory address of
    /// a specific touch remains the same, so use that as a key
    /// into a dictionary of fingerNext to retrieve an
    /// array of events. If this is the first time for a new finger
    /// then create a new array and add it dictionary of fingerNext.
    func updateTouches(_ touches: Set<UITouch>, _ event: UIEvent?) {

        for touch in touches {
            // create a touch time
            let nextXY = touch.preciseLocation(in: nil)
            let key = String(format: "%p", touch)

            if let touchVm = touchVmKey[key] {

                DispatchQueue.main.async {
                    switch touch.phase {
                        case .ended, .cancelled:
                            // call touchMenuUpdate directly since
                            // .zero is interpreted that touch that ended
                            self.touchVmKey.removeValue(forKey: key)
                            return touchVm.touchMenuUpdate(.zero)

                        default:
                            // call touchesUpdate which will translate
                            // location from global to SwiftUI menu location
                            return touchVm.touchMenuUpdate(nextXY)
                    }
                }

            } else if let finger = fingerKey[key] {
                // add touch item to an old finger, based on memory address
                return finger.cacheTouchItem(makeTouchItem(touch))
            } else {
                for touchVm in touchVms {
                    if touchVm.hitTest(nextXY) {
                        touchVmKey[key] = touchVm
                        return touchVm.touchMenuUpdate(nextXY)
                    }
                }
                touchCanvas(touch)
            }
        }
        func makeTouchItem(_ touch: UITouch) -> TouchItem {

            let key = String(format: "%p", touch)
            var force = touch.force
            func updateFilter(_ force: CGFloat) {
                let kForceFilter = CGFloat(0.25)
                filterForce = force * kForceFilter + filterForce * (1.0 - kForceFilter)
            }
            let nextXY = touch.preciseLocation(in: nil)
            let prevXY = touch.precisePreviousLocation(in: nil)
            let radius = touch.majorRadius
            let phase = touch.phase
            let time = event!.timestamp

            if force > 0 {
                switch phase {
                    case .began:                filterForce = 0.0001
                    case .stationary, .moved:   updateFilter(force)
                    case .ended, .cancelled:    filterForce = force
                    default: break
                }
                force = filterForce
            }
            let angle = touch.azimuthAngle(in: nil)
            let alti = (.pi/2 - touch.altitudeAngle) / .pi/2
            let azim = CGVector(dx: -sin(angle) * alti, dy: cos(angle) * alti)

            let item = TouchItem(key, time, prevXY, nextXY, radius, force, azim, phase)
            return item

        }
        func touchCanvas(_ touch: UITouch) {
            let key = String(format: "%p", touch)
            if let finger = fingerKey[key] {
                // add touch item to an old finger, based on memory address
                finger.cacheTouchItem(makeTouchItem(touch))
            } else {
                // add touch item to a new finger
                let finger = TouchFinger()
                fingerKey[key] = finger
                finger.cacheTouchItem(makeTouchItem(touch))
            }
            //item.logTouch()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, event) }

}
