//  Created by warren on 9/26/22.

import UIKit

struct TouchMenuItem: Codable {
    
    internal var time      : TimeInterval
    internal var cornerStr : String
    internal var menuKey   : Int
    internal var hashPath  : [Int]
    internal let nextX     : Float
    internal let nextY     : Float
    internal let phase     : Int // UITouch.Phase

    init(_ menuKey: Int,
         _ cornerStr: String,
         _ hashPath: [Int],
         _ nextXY: CGPoint,
         _ phase: UITouch.Phase) {

        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.hashPath = hashPath
        self.time = Date().timeIntervalSince1970
        self.nextX = Float(nextXY.x)
        self.nextY = Float(nextXY.y)
        self.phase = phase.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case menuKey, cornerStr, time, hashPath, nextX, nextY, phase }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try menuKey   = container.decode(Int.self   , forKey: .menuKey   )
        try cornerStr = container.decode(String.self, forKey: .cornerStr )
        try time      = container.decode(Double.self, forKey: .time      )
        try hashPath  = container.decode([Int].self , forKey: .hashPath  )
        try nextX     = container.decode(Float.self , forKey: .nextX     )
        try nextY     = container.decode(Float.self , forKey: .nextY     )
        try phase     = container.decode(Int.self   , forKey: .phase     )
    }

}

