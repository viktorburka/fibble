//
//  Workout.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class Workout {
    var id: Int
    var name: String
    var intervals: [Interval]
    var currentIntervalIdx = 0
    var hydrationReminderEnabled = true
    var heartRateAlertEnabled = true
    private var elapsed = 0.0
    private var currentIntervalElapsed = 0.0
    init(id: Int, name: String, intervals: [Interval], hydrationReminderEnabled: Bool = true, heartRateAlertEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.intervals = intervals
        self.hydrationReminderEnabled = hydrationReminderEnabled
        self.heartRateAlertEnabled = heartRateAlertEnabled
    }
    func currentInterval() -> Interval {
        return intervals[currentIntervalIdx]
    }
    func setElapsed(duration: TimeInterval) {
        self.elapsed = duration
        var low = 0.0, high = 0.0
        for index in 0..<intervals.count {
            let interval = intervals[index]
            high = low + interval.duration
            if duration >= low && duration <= high {
                currentIntervalIdx = index
                currentIntervalElapsed = duration - low
                break
            }
            low = high
        }
    }
    func intervalEnds(in duration: TimeInterval) -> Bool {
        let interval = currentInterval()
        return (interval.duration - currentIntervalElapsed) <= duration
    }
    func lastInterval() -> Bool {
        return currentIntervalIdx == (intervals.count - 1)
    }
    func nextInterval() -> Interval {
        if currentIntervalIdx + 1 < intervals.count {
            return intervals[currentIntervalIdx + 1]
        }
        return currentInterval()
    }
}

protocol Interval {
    var zone: HeartRateZone { get }
    var shortDescription: String { get }
    var description: String { get }
    var duration: TimeInterval { get }
}

struct Recovery: Interval {
    var zone = HeartRateZoneBuilder.byNumber(number: 1)
    var shortDescription = "Recovery"
    var description = "Recovery. Easy spin"
    var duration = entireWorkout
}

struct Instructed: Interval {
    var zone = HeartRateZone(number: 1, start: 1, end: infiniteHeartRate)
    var shortDescription: String
    var description: String
    var duration: TimeInterval
    init(shortDescription: String, description: String) {
        self.shortDescription = shortDescription
        self.description = description
        self.duration = entireWorkout
    }
    init(shortDescription: String, description: String, duration: TimeInterval) {
        self.shortDescription = shortDescription
        self.description = description
        self.duration = duration
    }
}

struct EnduranceMiles: Interval {
    var zone = HeartRateZoneBuilder.byNumber(number: 1)
    var shortDescription = "Endurance Miles"
    var description = "Endurance Miles"
    var duration = entireWorkout
}
