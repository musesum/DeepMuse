//
//  Platonic+defs.swift
//  HelloCube
//
//  Created by warren on 2/16/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.
//

import Foundation

extension Formatter {
    static let number = NumberFormatter()
}
public extension FloatingPoint {
    func digits(_ range: ClosedRange<Int>) -> String {
        Formatter.number.roundingMode = NumberFormatter.RoundingMode.halfEven
        Formatter.number.minimumFractionDigits = range.lowerBound
        Formatter.number.maximumFractionDigits = range.upperBound
        return Formatter.number.string(for:  self) ?? ""
    }
}

