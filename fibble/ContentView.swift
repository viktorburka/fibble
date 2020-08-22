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
        NavigationView {
            VStack {
                Button(action: {
                    //print("end workout")
                }) {
                    NavigationLink(destination: WorkoutScreen()) {
                        Text("Start Workout")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
