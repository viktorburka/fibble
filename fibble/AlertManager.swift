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
    var enabled = true
    var play = 0
    let frequency = 4 // play alert every Nth time
    init(enabled: Bool) {
        self.enabled = enabled
    }
    func heartRateAlert() {
        if play % frequency == 0 && enabled {
            AudioServicesPlaySystemSound(SystemSoundID(1151))
        }
        play += 1
    }
    func hydrationAlert() {
        if play % frequency == 0 && enabled {
            AudioServicesPlaySystemSound(SystemSoundID(1007))
        }
        play += 1
    }
}
