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

func dataToIntArr(data: Data) -> [Int] {
    var numbers: [Int] = []
    var iter = data.makeIterator()
    while true {
        guard
            let b1 = iter.next(),
            let b2 = iter.next(),
            let b3 = iter.next(),
            let b4 = iter.next(),
            let b5 = iter.next(),
            let b6 = iter.next(),
            let b7 = iter.next(),
            let b8 = iter.next()
        else {
            break
        }
        let num = Int(b1) << 56 | Int(b2) << 48 | Int(b3) << 40 | Int(b4) << 32 | Int(b5) << 24 | Int(b6) << 16 | Int(b7) << 8 | Int(b8)
        numbers.append(num)
    }
    return numbers
}
