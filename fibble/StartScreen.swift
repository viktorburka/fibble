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
    @State var store = WorkoutDataStore()
    var body: some View {
        NavigationView {
            VStack {
            VStack {
                Text("\(screenState.errorText)")
                    .opacity(self.screenState.state == .ok ? 0.0 : 1.0)
                    .foregroundColor(.red)
                Spacer().frame(height: 20)
                Button(action: startWorkout) {
                    NavigationLink(destination: WorkoutScreen()) {
                        Text("Start Workout")
                    }
                }
                Spacer().frame(height: 30)
                Button(action: startFtpTest) {
                    //NavigationLink(destination: WorkoutScreen()) {
                        Text("Start FTP Test")
                    //}
                }
                Spacer().frame(height: 80)
            }
            VStack {
                Divider()
                Text("Last Workout")
                    .font(.body)
                List(screenState.lastReport.reportData) { data in
                    HStack {
                        Text("\(data.label)").foregroundColor(.gray)
                        Spacer()
                        Text("\(data.value)").foregroundColor(.gray)
                    }
                }
                .frame(maxHeight: .infinity)
            }.frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            let result = self.store.lastWorkoutData()
            guard let workout = result.data else {
                print("error load last workout data: ", result.error)
                self.screenState.state = .error
                self.screenState.errorText = "Error load last workout data"
                return
            }
            self.screenState.lastReport.setWorkout(data: workout)
            //updateLastWorkoutReport(self)
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
    var reportData: [ReportData]
    static let template = [
        ReportData(id: 0, label: "Workout Start", value: ""),
        ReportData(id: 1, label: "Workout End", value: ""),
        ReportData(id: 2, label: "Avg Heart Rate", value: ""),
        ReportData(id: 3, label: "Calories", value: "")
    ]
    
    init() {
        reportData = WorkoutReport.template
    }
    
    static func buildReport(data: WorkoutData) -> [ReportData] {
        var report = WorkoutReport.template
        
        // start, end
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss E, d MMM y"
        report[0].value = fmt.string(from: data.start)
        report[1].value = fmt.string(from: data.end)
        
        // heart rate
        report[2].value = String(data.avgHeartRate)
        
        // calories
        report[3].value = String(data.calories)
        
        return report
    }
    
    func setWorkout(data: WorkoutData) {
        
    }
}
