//
//  StartScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/27/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct StartScreen: View {
    @State var screenState = StartScreenState()
    @ObservedObject var lastReport = WorkoutReport()
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("\(screenState.errorText)")
                        .opacity(self.screenState.state == .ok ? 0.0 : 1.0)
                        .foregroundColor(.red)
                    Spacer()
                        .frame(height: 20)
                    Text("\(screenState.workouts[screenState.currentWorkout].name)")
                    Spacer()
                        .frame(height: 20)
                    Button(action: startWorkout) {
                        NavigationLink(destination:
                            WorkoutScreen(workoutReport: self.lastReport)
                                .environmentObject(WorkoutModel(plan: self.screenState.workouts[self.screenState.currentWorkout]))
                        )
                        {
                            Text("Start Workout")
                        }
                    }
                    .contextMenu {
                        ForEach(screenState.workouts, id: \.id) { w in
                            Button(action: { self.screenState.currentWorkout = w.id }) {
                                Text(w.name)
                            }
                        }
                    }
                    Spacer().frame(height: 80)
                }
                VStack {
                    Divider()
                    Text("Last Workout - \(lastReport.hasError ? "Error" : String(lastReport.workoutId))")
                        .font(.body)
                        .foregroundColor(lastReport.hasError ? .red : .black)
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
            let store = LocalFileStore()
            do {
                let lastWorkoutId = try store.loadWorkoutStats().lastWorkoutId
                let workout = try store.workoutData(workoutId: lastWorkoutId)
                self.lastReport.reportData = WorkoutReport.buildReport(data: workout)
                self.lastReport.workoutId = workout.id
            } catch {
                self.screenState.state = .error
                self.screenState.errorText = "Error load last workout data"
            }
        }
    }
    
    func startWorkout() {
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
    var currentWorkout = 0
    
#if targetEnvironment(simulator)
    var workouts: [WorkoutPlan] = [
//        Workout(
//            id: 0,
//            name: "FTP Test",
//            intervals: [
//                Fragment(
//                    shortDescription: "Reach top speed",
//                    description: "Reach top speed",
//                    duration: 10.0
//                ),
//                Fragment(
//                    shortDescription: "Speed you can barely maintain",
//                    description: "High cadence, reach speed you can barely maintain",
//                    duration: 10.0
//                ),
//                Fragment(
//                    shortDescription: "Recovery",
//                    description: "Recovery",
//                    duration: 10.0
//                )
//            ],
//            hydrationReminderEnabled: false,
//            heartRateAlertEnabled: false,
//            displayHeartRateZones: false
//        )
        WorkoutPlan(
            id: 0,
            name: "Recovery",
            intervals: [
                Fragment(
                    shortDescription: "Recovery",
                    description: "Recovery",
                    duration: 10.0,
                    zone: HeartRateZoneBuilder.byNumber(number: 1)
                )
            ],
            hydrationReminderEnabled: true,
            heartRateAlertEnabled: true
        )
    ]
#else
    var workouts: [WorkoutPlan] = [
        WorkoutPlan(
            id: 0,
            name: "Recovery",
            intervals: [
                Fragment(
                    shortDescription: "Recovery",
                    description: "Recovery",
                    duration: infiniteDuration
                )
            ]
        ),
        WorkoutPlan(
            id: 1,
            name: "FTP Test",
            intervals: [
                Fragment(
                    shortDescription: "Reach top speed",
                    description: "Reach top speed",
                    duration: 60.0
                ),
                Fragment(
                    shortDescription: "Speed you can barely maintain",
                    description: "High cadence, reach speed you can barely maintain",
                    duration: 6 * 60.0
                ),
                Fragment(
                    shortDescription: "Top speed",
                    description: "Top speed",
                    duration: 60.0
                ),
                Fragment(
                    shortDescription: "Recovery",
                    description: "Recovery",
                    duration: 10 * 60.0
                )
            ],
            hydrationReminderEnabled: false,
            heartRateAlertEnabled: false,
            displayHeartRateZones: false
        ),
        WorkoutPlan(
            id: 2,
            name: "Endurance Miles",
            intervals: [
                Fragment(
                    shortDescription: "Endurance Miles",
                    description: "Endurance Miles",
                    duration: infiniteDuration
                )
            ]
        )
    ]
#endif
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
    var startTime = Date()
    var endTime = Date()
    var hasError = false
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


