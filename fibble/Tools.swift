//
//  Tools.swift
//  fibble
//
//  Created by Viktor Burka on 8/23/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

enum MainScreenState {
    case ok
    case error
}

struct Zone {
    var start, end: Int
}

func updateZoneHighlight(heartRate: Int, zones: [Zone]) -> [Bool] {
    var highlights: [Bool] = []
    for zone in zones {
        highlights.append(heartRate >= zone.start && heartRate <= zone.end)
    }
    return highlights
}
