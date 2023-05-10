//  Created by warren on 1/3/23.

public struct TouchMenuLocalItem: Codable {

    public var time   : TimeInterval
    public var menuKey: Int
    public let xy     : [Double]
    public let phase  : Int // UITouch.Phase

    public init(_ touch: UITouch) {
        self.time    = Date().timeIntervalSince1970
        self.menuKey = touch.hash
        self.xy      = touch.location(in: nil).doubles()
        self.phase   = touch.phase.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case time, menuKey, xy, phase }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try time    = container.decode(Double  .self, forKey: .time   )
        try menuKey = container.decode(Int     .self, forKey: .menuKey)
        try xy      = container.decode([Double].self, forKey: .xy     )
        try phase   = container.decode(Int     .self, forKey: .phase  )
    }
}

