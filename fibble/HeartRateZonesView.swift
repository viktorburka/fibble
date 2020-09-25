//
//  HeartRateZonesView.swift
//  fibble
//
//  Created by Viktor Burka on 9/10/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct HeartRateZonesView: View {
    var zones: [HeartRateZone] = []
    @Binding var heartRate: Int
    @Binding var heartRateOutOfRange: Bool
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(zones, id: \.number) { z in
                Text(String(format: "Z%d  %d-%d", z.number, z.start, z.end))
                    .opacity(self.isHighlighted(zone: z, heartRate: self.heartRate) ? 1 : 0)
                    .foregroundColor(self.heartRateOutOfRange ? .red : self.isHighlighted(zone: z, heartRate: self.heartRate) ? .black : .gray)
            }
        }
        .font(Font.system(size: 18).bold())
    }
    
    func isHighlighted(zone: HeartRateZone, heartRate: Int) -> Bool {
        if zone.number == 1 && heartRate <= zone.start {
            return true
        }
        return zone.start <= heartRate && heartRate <= zone.end
    }
}

struct HeartRateZonesView_Previews: PreviewProvider {
    @State static var heartRate = 100
    @State static var outOfRange = false
    static var previews: some View {
        HeartRateZonesView(heartRate: $heartRate, heartRateOutOfRange: $outOfRange)
    }
}
