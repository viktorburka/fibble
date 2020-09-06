//
//  HydrationReminder.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

struct HydrationReminder {
    let remindEveryMinutes = 15
    let reminderDurationSec = 20
    var formatter: TimeDurationFormatter
    var hydrationDue: Bool {
        get {
            return formatter.minutes % remindEveryMinutes == 0 &&
                   formatter.seconds <= reminderDurationSec
        }
    }
}
