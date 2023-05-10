
import UIKit
import MuPar // Visitor

struct TouchCanvasItem: Codable {
    
    internal var key     : Int      // unique id of touch
    internal var time    : Double   // time event was created
    internal var nextX   : Float    // touch point x
    internal var nextY   : Float    // touch point y
    internal var force   : Float    // pencil pressure
    internal var radius  : Float    // size of dot
    internal var azimX   : Double   // pencil tilt X
    internal var azimY   : Double   // pencil tilt Y
    internal var phase   : Int      // UITouch.Phase.rawValue
    internal var from    : Int      // Visitor.from
    
    init(_ key      : Int,
         _ next     : CGPoint,
         _ radius   : Float,
         _ force    : Float,
         _ azimuth  : CGVector,
         _ phase    : UITouch.Phase,
         _ visit  : Visitor) {
        
        // tested timeDrift between UITouches.time and Date() is around 30 msec
        self.time   = Date().timeIntervalSince1970
        
        self.key    = key
        self.nextX  = Float(next.x)
        self.nextY  = Float(next.y)
        self.radius = Float(radius)
        self.force  = Float(force)
        self.azimX  = azimuth.dx
        self.azimY  = azimuth.dy
        self.phase  = Int(phase.rawValue)
        self.from   = visit.from.rawValue

    }
    
    enum CodingKeys: String, CodingKey {
        case key, time, nextX, nextY, radius, force, azimX, azimY, phase, from }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try key    = container.decode(Int   .self, forKey: .key   )
        try time   = container.decode(Double.self, forKey: .time  )
        try nextX  = container.decode(Float .self, forKey: .nextX )
        try nextY  = container.decode(Float .self, forKey: .nextY )
        try radius = container.decode(Float .self, forKey: .radius)
        try force  = container.decode(Float .self, forKey: .force )
        try azimX  = container.decode(Double.self, forKey: .azimX )
        try azimY  = container.decode(Double.self, forKey: .azimY )
        try phase  = container.decode(Int   .self, forKey: .phase )
        try from   = container.decode(Int   .self, forKey: .from  )
    }

    var visitFrom: String {
        VisitFrom(rawValue: from).log
    }
    func visit() -> Visitor {
        return Visitor(VisitFrom(rawValue: from))
    }
    func logTouch() {
        if phase == UITouch.Phase.began.rawValue { print() } // space for new stroke
        print(String(format:"%.3f →(%3.f,%3.f) 𝝙%5.1f f: %.3f r: %.2f %s",
                     time, nextX, nextY, force, radius, visitFrom))
    }
    func isDone() -> Bool {
        return (phase == UITouch.Phase.ended    .rawValue ||
                phase == UITouch.Phase.cancelled.rawValue )
    }
}

