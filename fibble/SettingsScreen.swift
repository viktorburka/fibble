//
//  SettingsScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/27/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct SettingsScreen: View {
    @State var settings: Settings = Settings()
    var body: some View {
        Form {
            Text("Settings").font(.title)
            Section {
                Text("Heart Rate Zones").font(.headline)
                ForEach(settings.heartRateZones, id: \.self) { hrz in
                    HStack {
                        Text(String(format: "Zone %d", hrz.number))
                        Spacer()
                        Text(String(format: "%d-%d", hrz.start, hrz.end))
                    }
                }
            }
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
