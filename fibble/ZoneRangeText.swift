//
//  ZoneRangeText.swift
//  fibble
//
//  Created by Viktor Burka on 8/26/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct ZoneRangeText: View {
    @State var zone: Zone
    var body: some View {
        Text(String(format: "Z%d  %d-%d", zone.number, zone.start, zone.end))
            .opacity(zone.highlighted ? 1 : 0)
    }
}

struct ZoneRangeText_Previews: PreviewProvider {
    static var previews: some View {
        ZoneRangeText(zone: Zone(number: 1, start: 126, end: 137, highlighted: true))
    }
}
