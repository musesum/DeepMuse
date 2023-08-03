//
//  GauseTimeVal.swift
//  DeepMuse
//
//  Created by warren on 8/1/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation


class GaussTimeVal {

    var durationStart: TimeInterval
    var durationTotal: TimeInterval
    var timeStart: TimeInterval
    var timeWarp: TimeInterval // warped time for easeIn Out
    var timeTarget: TimeInterval

    var valsStart = [Double]()
    var valsCurrent = [Double]()

    private var timeVals = [TimeVals]()
    var valCount = 0
    var startTime = TimeInterval(0)
    var currentTime = TimeInterval(0)


    public init(_ duration: TimeInterval) {
        self.durationStart = duration
        self.durationTotal = duration

    }

    func addTweVals(_ twes: [Double],
                    _ vals: [Double]) {

        verifyValCount()
        let distance = twes ∆ vals
        let time = Date().timeIntervalSince1970

        if timeVals.isEmpty {
            timeVals.append(TimeVals(time, twes))
        }
        timeVals.append(TimeVals(time + durationTotal, vals))

        func verifyValCount() {
            if valCount == 0 {
                valCount = vals.count
            } else if vals.count != valCount {
                print("⁉️ CubicPolyVal: mismatched vals.count: \(vals.count) != valCount:  \(valCount)")
            }
        }
    }

    func timeSegmentStart(_ time: TimeInterval) -> Int {
        var segStart = 0
        for i in 0 ..< timeVals.count {
            if timeVals[i].time < time {
                segStart = i
            } else {
                break
            }
        }
        return segStart
    }

    func finish() {
        timeVals.removeAll()
        valCount = 0
    }

    func getTweenNow(_ time: TimeInterval) -> [Double] {


    }
}

