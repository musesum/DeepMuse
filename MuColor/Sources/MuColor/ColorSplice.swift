//  Created by warren on 7/30/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation

public struct ColorSplice: OptionSet {

    public let rawValue: Int

    public static let gradient = ColorSplice(rawValue: 1 << 0) // smooth gradient between left and right
    public static let black = ColorSplice(rawValue: 1 << 1)    // left and right are black
    public static let white = ColorSplice(rawValue: 1 << 2)    // left and right are white
    public static let zeno = ColorSplice(rawValue: 1 << 3)     // zeno fractalize 1/2 + 1/4 + 1/8 ...
    public static let flip = ColorSplice(rawValue: 1 << 4)     // flip right to left

    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    public init(with: String) {
        self.init()
        for char in with {
            switch char {
            case "/": self.insert(.gradient)
            case "K": self.insert(.black)
            case "W": self.insert(.white)
            case "Z": self.insert(.zeno)
            case "F": self.insert(.flip)
            default: continue
            }
        }
    }
}
