//
//  AlertManager.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation
import AudioToolbox

class AlertManager {

    enum Reminder: Int {
        case heartRate = 0, hydration, intervalEnd, workoutEnd
    }
    
    class TrackingInfo {
        var steps: Int
        var frequency: Int
        init(frequency: Int) {
            self.frequency = frequency
            self.steps = frequency // to trigger on first call
        }
        func reset() { self.steps = 1 }
        func inc() { self.steps = self.steps + 1 }
    }
    
    let tracking = [
        Reminder.heartRate:   TrackingInfo(frequency: 4),
        Reminder.hydration:   TrackingInfo(frequency: 4),
        Reminder.intervalEnd: TrackingInfo(frequency: 2),
        Reminder.workoutEnd:  TrackingInfo(frequency: 2)
    ]
    
    var enabled = true
    var muted = false
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func mute() { self.muted = true }
    
    func unmute() { self.muted = false }
    
    func heartRateAlert() {
        let t = tracking[Reminder.heartRate]!
        if enabled && !muted && (t.steps % t.frequency == 0) {
            AudioServicesPlaySystemSound(SystemSoundID(1151))
            t.reset()
        } else {
            t.inc()
        }
    }
    
    func hydrationAlert() {
        let t = tracking[Reminder.hydration]!
        if enabled && !muted && (t.steps % t.frequency == 0) {
            AudioServicesPlaySystemSound(SystemSoundID(1007))
            t.reset()
        } else {
            t.inc()
        }
    }
    
    func intervalEndAlert() {
        let t = tracking[Reminder.intervalEnd]!
        if enabled && !muted && (t.steps % t.frequency == 0) {
            AudioServicesPlaySystemSound(SystemSoundID(1007))
            t.reset()
        } else {
            t.inc()
        }
    }
    
    func workoutEndAlert() {
        let t = tracking[Reminder.workoutEnd]!
        if enabled && !muted && (t.steps % t.frequency == 0) {
            AudioServicesPlaySystemSound(SystemSoundID(1007))
            t.reset()
        } else {
            t.inc()
        }
    }
}
