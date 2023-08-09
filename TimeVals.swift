//
//  TimeVals.swift
//  DeepMuse
//
//  Created by warren on 8/1/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation

class TimeVals {

    let time: TimeInterval
    var vals: [Double] // 1,2,3D
    init(_ time: TimeInterval, _ vals: [Double]) {
        self.time = time
        self.vals = vals
    }
    func add(_ val: Double) {
        vals.append(val)
    }
}
