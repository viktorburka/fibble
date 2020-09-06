//
//  HeartRateEvaluator.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

struct HeartRateEvaluator {
    var heartRate: Int
    var zoneLow: Int
    var zoneHigh: Int
    var zoneNumber: Int
    var outOfRange: Bool {
        get {
            if heartRate < zoneLow && zoneNumber != 1 {
                return true
            }
            if heartRate > zoneHigh {
                return true
            }
            return false
        }
    }
}
