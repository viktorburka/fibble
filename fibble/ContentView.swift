//
//  ContentView.swift
//  fibble
//
//  Created by Viktor Burka on 8/18/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    let store: WorkoutDataStore
    @State var state: MainScreenState = .ok
    @State var errorText: String = "Unknown error"
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    //print("end workout")
                }) {
                    NavigationLink(destination: WorkoutScreen(store: store)) {
                        Text("Start Workout")
                    }
                }
                
                Text("\(errorText)")
                    .opacity(self.state == .ok ? 0 : 1)
            }
        }.onAppear() {
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: WorkoutDataStore())
    }
}
