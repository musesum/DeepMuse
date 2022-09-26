
import UIKit

struct TouchCanvasItem {

    internal var time: TimeInterval
    internal let prev: CGPoint
    internal let next: CGPoint
    internal let force: CGFloat
    internal let radius: CGFloat
    internal let azimuth: CGVector
    internal let phase: UITouch.Phase

    init(_ time: TimeInterval,
         _ prev: CGPoint,
         _ next: CGPoint,
         _ radius: CGFloat,
         _ force: CGFloat,
         _ azimuth: CGVector,
         _ phase: UITouch.Phase) {

        self.prev = prev
        self.next = next
        self.radius = radius
        self.force = force
        self.azimuth = azimuth
        self.phase = phase
        self.time = time
    }

    func logTouch() {
        let delta = CGPoint(x: next.x - prev.x, y: next.y - prev.y)
        let distance = sqrt(delta.x * delta.x + delta.y * delta.y)
        if phase == .began { print() } // space for new stroke
        print(String(format:"%.3f →(%3.f,%3.f) 𝝙%5.1f f: %.3f r: %.2f",
                     time, next.x, next.y, distance, force, radius))
    }
}

