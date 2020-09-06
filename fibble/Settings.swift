//
//  Settings.swift
//  fibble
//
//  Created by Viktor Burka on 8/27/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

struct Settings {
    var heartRateZones = [HeartRateZone]()
    
    init() {
        heartRateZones = [
            HeartRateZone(number: 1, start: 126, end: 137),
            HeartRateZone(number: 2, start: 138, end: 150),
            HeartRateZone(number: 3, start: 151, end: 163),
            HeartRateZone(number: 4, start: 164, end: 174),
            HeartRateZone(number: 5, start: 175, end: 186)
        ]
    }
}

struct HeartRateZone: Hashable {
    var number: Int
    var start, end: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    static func == (lhs: HeartRateZone, rhs: HeartRateZone) -> Bool {
        return lhs.number == rhs.number &&
               lhs.start == rhs.start &&
               lhs.end == rhs.end
    }
}

struct HeartRateZoneBuilder {
    static func byNumber(number: Int) -> HeartRateZone {
        let s = Settings()
        return s.heartRateZones[number-1]
    }
}
