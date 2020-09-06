//
//  Workout.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

protocol Workout {
    var id: Int { get }
    var name: String { get }
    var intervals: [Interval] { get }
    func currentInterval() -> Interval
}

struct RecoveryWorkout: Workout {
    var id = 0
    var name = "Recovery"
    var intervals: [Interval] = [Recovery()]
    var currentIntervalIdx = 0
    func currentInterval() -> Interval {
        return intervals[currentIntervalIdx]
    }
}

struct FtpTest: Workout {
    var id = 1
    var name = "FTP Test"
    var intervals: [Interval] = [Unlimited()]
    var currentIntervalIdx = 0
    func currentInterval() -> Interval {
        return intervals[currentIntervalIdx]
    }
}

protocol Interval {
    var zone: HeartRateZone { get }
}

struct Recovery: Interval {
    var zone = HeartRateZoneBuilder.byNumber(number: 1)
}

struct Unlimited: Interval {
    var zone = HeartRateZone(number: 1, start: 1, end: 200)
}
