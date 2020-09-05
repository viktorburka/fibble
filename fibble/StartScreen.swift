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
    @ObservedObject var lastReport = WorkoutReport()
    @ObservedObject var currentWorkout = CurrentWorkout()
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("\(screenState.errorText)")
                        .opacity(self.screenState.state == .ok ? 0.0 : 1.0)
                        .foregroundColor(.red)
                    Spacer()
                        .frame(height: 20)
                    Text("\(screenState.workouts[currentWorkout.id].name)")
                    Spacer()
                        .frame(height: 20)
                    Button(action: startWorkout) {
                        NavigationLink(destination: WorkoutScreen(lastReport: self.lastReport, currentWorkout: self.currentWorkout)) {
                            Text("Start Workout")
                        }
                    }
                    .contextMenu {
                        ForEach(screenState.workouts) { w in
                            Button(action: { self.currentWorkout.id = w.id }) {
                                Text(w.name)
                            }
                        }
                    }
                    Spacer().frame(height: 80)
                }
                VStack {
                    Divider()
                    Text("Last Workout - \(lastReport.workoutId)")
                        .font(.body)
                    List(self.lastReport.reportData) { data in
                        HStack {
                            Text("\(data.label)").foregroundColor(.gray)
                            Spacer()
                            Text("\(data.value)").foregroundColor(.gray)
                        }
                    }
                }.frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            let result = self.store.lastWorkoutData()
            guard let workout = result.data else {
                print("error load last workout data:", result.error)
                self.screenState.state = .error
                self.screenState.errorText = "Error load last workout data"
                return
            }
            self.lastReport.reportData = WorkoutReport.buildReport(data: workout)
            self.lastReport.workoutId = workout.id
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

//enum WorkoutType: CaseIterable, Identifiable {
//    case recovery
//    case ftpTest
//    var id: String { self.rawValue }
//}

struct StartScreenState {
    var state: ScreenState = .ok
    var errorText = "Unknown error"
    var currentWorkout = 0
    let workouts = [
        Workout(id: 0, name: "Recovery"),
        Workout(id: 1, name: "FTP Test")
    ]
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

class WorkoutReport: ObservableObject {
    @Published var reportData = [ReportData]()
    @Published var workoutId = 0
    static let template = [
        ReportData(id: 0, label: "Workout Time", value: ""),
        ReportData(id: 1, label: "Duration", value: ""),
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
        fmt.dateFormat = "h:mm a"
        let startStr = fmt.string(from: data.start)
        let endStr = fmt.string(from: data.end)
        report[0].value = String(format: "%@ - %@", startStr, endStr)
        
        // duration
        let duration = data.start.distance(to: data.end)
        report[1].value = formatDuration(duration: duration)

        // heart rate
        report[2].value = String(format: "%d bpm", data.avgHeartRate)
        
        // calories
        let weightKg = 79.0
        let age = 36.0
        let v1 = 0.6309 * Double(data.avgHeartRate)
        let v2 = 0.1988 * weightKg
        let v3 = 0.2017 * age
        let calories = ((-55.0969 + v1 + v2 + v3)/4.184) * duration / 60.0
        report[3].value = String(format: "%.1f cal", calories)
        
        return report
    }
}

func formatDuration(duration: TimeInterval) -> String {
    return String(format: "%02d:%02d:%02d", Int(duration) / 3600, Int(duration) / 60 % 60, Int(duration) % 60)
}

class CurrentWorkout: ObservableObject {
    @Published var id = 0
}

struct Workout: Identifiable {
    var id: Int
    var name: String
}
