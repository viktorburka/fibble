//
//  TimeDurationFormatter.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

struct TimeDurationFormatter {
    let interval: TimeInterval
    var hours: Int {
        get {
            return Int(interval) / 3600
        }
    }
    var minutes: Int {
        get {
            return Int(interval) / 60 % 60
        }
    }
    var seconds: Int {
        get {
            return Int(interval) % 60
        }
    }
}
