//
//  Settings.swift
//  fibble
//
//  Created by Viktor Burka on 8/27/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

let infiniteHeartRate = 1000
let infiniteDuration = TimeInterval(24 * 60 * 60) // sec

struct Settings {
    enum HeartRateCalculationStrategy {
        case ftpTest, manual
    }
    var heartRateZones: [HeartRateZone]
    var heartRateCalculation: HeartRateCalculationStrategy
    var ftpTestAvgHeartRate: Int
    
    init() {
        heartRateZones = [
            HeartRateZone(number: 1, start: 126, end: 137),
            HeartRateZone(number: 2, start: 138, end: 150),
            HeartRateZone(number: 3, start: 151, end: 163),
            HeartRateZone(number: 4, start: 164, end: 174),
            HeartRateZone(number: 5, start: 175, end: 186)
        ]
        heartRateCalculation = HeartRateCalculationStrategy.ftpTest
        ftpTestAvgHeartRate = 154
    }
}


struct HeartRateZone: Hashable {
    var number: Int
    var start, end: Int
    var valid: Bool
    
    init() {
        number = 0
        start = 0
        end = 0
        valid = false
    }
    
    init(number: Int, start: Int, end: Int) {
        self.number = number
        self.start = start
        self.end = end
        self.valid = start < end
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    static func ==(lhs: HeartRateZone, rhs: HeartRateZone) -> Bool {
        return lhs.number == rhs.number &&
               lhs.start == rhs.start &&
               lhs.end == rhs.end
    }
}

struct HeartRateZoneBuilder {
    static func byNumber(number: Int) -> HeartRateZone {
        let s = Settings()
        if s.heartRateCalculation == .manual {
            if s.heartRateZones.indices.contains(number-1) {
                return s.heartRateZones[number-1]
            }
            return HeartRateZone()
        }
        let zones = zonesByFtpAvg(heartRate: s.ftpTestAvgHeartRate)
        if zones.indices.contains(number-1) {
            return zones[number-1]
        }
        return HeartRateZone()
    }
    
    static func allZones() -> [HeartRateZone]? {
        let s = Settings()
        if s.heartRateCalculation == .manual {
            return s.heartRateZones
        }
        return zonesByFtpAvg(heartRate: s.ftpTestAvgHeartRate)
    }
}

func zonesByFtpAvg(heartRate: Int) -> [HeartRateZone] {
    var zones = [HeartRateZone]()
    if heartRate <= 0 {
        return zones
    }
    zones.append(HeartRateZone(number: 1, start: Int(0.5*Double(heartRate)),  end: Int(0.91*Double(heartRate))))
    zones.append(HeartRateZone(number: 2, start: Int(0.88*Double(heartRate)), end: Int(0.9*Double(heartRate))))
    zones.append(HeartRateZone(number: 3, start: Int(0.92*Double(heartRate)), end: Int(0.94*Double(heartRate))))
    zones.append(HeartRateZone(number: 4, start: Int(0.95*Double(heartRate)), end: Int(0.97*Double(heartRate))))
    zones.append(HeartRateZone(number: 5, start: heartRate, end: infiniteHeartRate))
    return zones
}
