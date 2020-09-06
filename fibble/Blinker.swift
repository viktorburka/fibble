//
//  Blinker.swift
//  fibble
//
//  Created by Viktor Burka on 9/5/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class Blinker {
    var enabled = false
    var show = 0
    let frequency = 2
    var visible: Bool {
        get {
            if !enabled {
                return false
            }
            let v = show % frequency == 0
            show += 1
            return v
        }
    }
}
