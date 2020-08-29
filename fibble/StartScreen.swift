//
//  StartScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/27/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct StartScreen: View {
    @State var screenState: StartScreenState = StartScreenState()
    var body: some View {
        NavigationView {
            VStack {
                Text("\(screenState.errorText)")
                    .opacity(self.screenState.state == .ok ? 0.0 : 1.0)
                Button(action: startWorkout) {
                    NavigationLink(destination: WorkoutScreen()) {
                        Text("Start Workout")
                    }
                }
                Spacer()
                    .frame(height: 50)
                Button(action: startFtpTest) {
                    NavigationLink(destination: WorkoutScreen()) {
                        Text("Start FTP Test")
                    }
                }
                Divider()
                Text("Last Workout")
                    .font(.body)
                List(screenState.lastReport.reportData) { data in
                    HStack {
                        Text("\(data.label)")
                        Spacer()
                        Text("\(data.value)")
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear {
        
        }
    }
    
    func startWorkout() {
        
    }
    
    func startFtpTest() {
        
    }
}

struct StartScreen_Previews: PreviewProvider {
    static var previews: some View {
        StartScreen(screenState: StartScreenState())
    }
}

struct StartScreenState {
    var state: ScreenState = .ok
    var errorText = "Unknown error"
    var lastReport = WorkoutReport()
}

enum ScreenState {
    case ok
    case error
}

struct ReportData: Identifiable {
    var id: Int
    var label = String()
    var value = String()
}

struct WorkoutReport {
    var start = Date()
    var end = Date()
    var avgHeartRate = 0
    var calories = 0
    var reportData = [ReportData]()
}
