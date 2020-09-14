//
//  Workout.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class WorkoutPlan: ObservableObject {
    var id = 0
    var name = ""
    var fragments = [Fragment]()
    var currentFragmentIndex = 0
    var hydrationReminderEnabled = true
    var heartRateAlertEnabled = true
    var displayHeartRateZones = true
    
    private var elapsed = 0.0
    private var totalFragmentsDuration = 0.0

    init(id: Int, name: String, intervals: [Fragment],
         hydrationReminderEnabled: Bool = true,
         heartRateAlertEnabled: Bool = true,
         displayHeartRateZones: Bool = true) {
        
        self.id = id
        self.name = name
        self.fragments = intervals
        self.hydrationReminderEnabled = hydrationReminderEnabled
        self.heartRateAlertEnabled = heartRateAlertEnabled
        self.displayHeartRateZones = displayHeartRateZones
        for fragment in fragments {
            self.totalFragmentsDuration += fragment.duration
        }
    }
    
    init() {
        fragments = [Fragment(shortDescription: "", description: "")]
    }
    
    func currentFragment() -> Fragment {
        return fragments[currentFragmentIndex]
    }
    
    func isOver() -> Bool {
        return elapsed >= totalFragmentsDuration
    }
    
    // Updates workout elpased time. If the time is beyond current segment,
    // last segment will always be current.
    func update(duration: TimeInterval) {
        self.elapsed = duration
        var low = 0.0, high = 0.0
        for index in 0..<fragments.count {
            let fragment = fragments[index]
            high = low + fragment.duration
            if duration >= low && duration <= high {
                currentFragmentIndex = index
                fragment.elapsed = duration - low
                break
            }
            low = high
        }
    }

    func ends(in duration: TimeInterval) -> Bool {
        return lastFragment() && currentFragment().ends(in: duration)
    }

    func lastFragment() -> Bool {
        return currentFragmentIndex == (fragments.count - 1)
    }
    
    func nextFragment() -> Fragment {
        if currentFragmentIndex + 1 < fragments.count {
            return fragments[currentFragmentIndex + 1]
        }
        return currentFragment()
    }
}

class Fragment {
    var zone = HeartRateZone(number: 1, start: 1, end: infiniteHeartRate)
    var shortDescription: String
    var description: String
    var duration: TimeInterval
    var elapsed: TimeInterval
    var recordHeartRate: Bool
    
    init(shortDescription: String, description: String, recordHeartRate: Bool = true) {
        self.shortDescription = shortDescription
        self.description = description
        self.duration = infiniteDuration
        self.elapsed = 0.0
        self.recordHeartRate = recordHeartRate
    }
    
    convenience init(shortDescription: String, description: String, duration: TimeInterval, recordHeartRate: Bool = true) {
        self.init(shortDescription: shortDescription, description: description, recordHeartRate: recordHeartRate)
        self.duration = duration
    }
    
    convenience init(shortDescription: String, description: String, duration: TimeInterval, zone: HeartRateZone, recordHeartRate: Bool = true) {
        self.init(shortDescription: shortDescription, description: description, duration: duration, recordHeartRate: recordHeartRate)
        self.zone = zone
    }
    
    func ends(in timeLeft: TimeInterval) -> Bool {
        return duration - elapsed <= timeLeft
    }
}
