//
//  HeartRateMonitor.swift
//  fibble
//
//  Created by Viktor Burka on 9/10/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol HeartRateProvider {
    func getHeartRate() -> Int
}

class HeartRateMonitor: HeartRateProvider {
    var heartRateListener: HeartRateListener
    var centralManager: CBCentralManager
    
    init() {
        heartRateListener = HeartRateListener()
        centralManager = CBCentralManager(delegate: heartRateListener, queue: nil)
    }
    
    func getHeartRate() -> Int {
        return heartRateListener.getHeartRate()
    }
}

class HeartRateSimulator: HeartRateProvider {
    //var values = [80, 82, 85, 88, 90, 91, 92, 95, 97, 99, 100, 105, 106, 108, 111, 115, 118, 121, 125]
    var values = [80, 130, 140, 141, 142, 143]
    var nextValue = 0
    func getHeartRate() -> Int {
        let currentHeartRate = values[nextValue]
        nextValue += 1
        nextValue = nextValue % values.count
        return currentHeartRate
    }
}
