
import UIKit

var TouchTimeStart = [String: CFTimeInterval]()

class TouchItem: NSObject {

    internal var time = TimeInterval(0)
    internal var prev = CGPoint.zero
    internal var next = CGPoint.zero
    internal var force = CGFloat(0)
    internal var radius = CGFloat(0)
    internal var azimuth = CGVector.zero
    internal var phase = UITouch.Phase.began

    init(_ key: String,
         _ time: TimeInterval,
         _ prev: CGPoint,
         _ next: CGPoint,
         _ radius: CGFloat,
         _ force: CGFloat,
         _ azimuth: CGVector,
         _ phase: UITouch.Phase) {

        super.init()

        self.prev = prev
        self.next = next
        self.radius = radius
        self.force = force
        self.azimuth = azimuth
        self.phase = phase
        if phase == .began {
            TouchTimeStart[key] = time; self.time = 0
        }
        self.time = time - (TouchTimeStart[key] ?? 0)
        if [.ended, .cancelled].contains(phase) {
            TouchTimeStart.removeValue(forKey: key)
        }
    }

    func logTouch() {
        let delta = CGPoint(x: next.x - prev.x, y: next.y - prev.y)
        let distance = sqrt(delta.x * delta.x + delta.y * delta.y)
        if phase == .began { print() } // space for new stroke
        print(String(format:"%.3f →(%3.f,%3.f) 𝝙%5.1f f: %.3f r: %.2f",
                     time, next.x, next.y, distance, force, radius))
    }
}
