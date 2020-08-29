//
//  Tools.swift
//  fibble
//
//  Created by Viktor Burka on 8/23/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class Zone: Hashable, Identifiable {
    var id: Int { get { return number } }
    var number: Int
    var start, end: Int
    var highlighted: Bool
    
    init(number: Int, start: Int, end: Int, highlighted: Bool) {
        self.number = number
        self.start = start
        self.end = end
        self.highlighted = highlighted
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    func updateHighlighting(heartRate: Int) {
        if number == 1 && heartRate < start {
            highlighted = true
            return
        }
        highlighted = heartRate >= start && heartRate <= end
    }
    
    static func == (lhs: Zone, rhs: Zone) -> Bool {
        return lhs.number == rhs.number &&
               lhs.start == rhs.start &&
               lhs.end == rhs.end &&
               lhs.highlighted == rhs.highlighted
    }
}
