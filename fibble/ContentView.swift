//
//  ContentView.swift
//  fibble
//
//  Created by Viktor Burka on 8/18/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        TabView {
            StartScreen()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Workout")
                }
            SettingsScreen()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Settings")
                }
        }
        .onAppear() {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
