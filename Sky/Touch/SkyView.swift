
import UIKit

class SkyView: UIView, UIGestureRecognizerDelegate {

    static let shared = SkyView()
    
    var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch
    var fingerNext = [String: TouchFinger]()
    var fingerPrev = [String: TouchFinger]()
    var touchRepeat = false // repeat touch, even when not moving finger

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

        let _ = SkyDraw.shared //TODO: circular reference?
    }

    /// for each finger, iterate intermediate points, with closure
    /// Previous version used to draw directly into buf, but now passes a closure
    func flushFingersBuf(_ draw: @escaping (CGPoint, CGFloat)->(), _ done: @escaping ()->()) {

        for (key, finger) in fingerNext {
            finger.flushCacheBuf(draw)
            if finger.isDone {
                fingerNext.removeValue(forKey: key)
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
    func updateTouches(_ touches: Set<UITouch>, with event: UIEvent?) {

        func updateFilter(_ force: CGFloat) {
            let kForceFilter = CGFloat(0.25)
            filterForce = force * kForceFilter + filterForce * (1.0 - kForceFilter)
        }

        let time = event!.timestamp

        for touch in touches {
            // create a touch time
            let prev = touch.precisePreviousLocation(in: nil)
            let next = touch.preciseLocation(in: nil)
            let radius = touch.majorRadius
            let phase = touch.phase
            var force = touch.force

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
            let key = String(format: "%p", touch)

            let item = TouchItem(key, time, prev, next, radius, force, azim, phase)

            // add touch item to an old finger, based on memory address
            if let finger = fingerNext[key] {
                 finger.cacheTouchItem(item)
            }
            // add touch item to a new finger
            else {
                let finger = TouchFinger()
                fingerNext[key] = finger
                finger.cacheTouchItem(item)
            }
            //item.logTouch()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, with: event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, with: event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, with: event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches, with: event) }

}
