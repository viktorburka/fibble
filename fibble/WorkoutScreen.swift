//
//  WorkoutScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/21/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

let focusedFont = Font.system(size: 80).monospacedDigit()

struct WorkoutScreen: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var workoutReport: WorkoutReport
    @ObservedObject var screenState = WorkoutScreenState()
    @EnvironmentObject var workoutModel: WorkoutModel
    
    var body: some View {
        VStack {
            ElapsedTimeView(elapsed: $workoutModel.elapsedTime)
                .font(Font.system(size: 80).monospacedDigit())
            Spacer()
            HStack() {
                Spacer()
                HStack(alignment: .top) {
                    Text("\(workoutModel.heartRate)")
                        .font(focusedFont)
                    PulseView(pulse: $workoutModel.pulse)
                }
                if workoutModel.connectionState == .ready {
                    if validHeartRateZones(zones: HeartRateZoneBuilder.allZones()) && workoutModel.workout.displayHeartRateZones {
                        HeartRateZonesView(zones: HeartRateZoneBuilder.allZones()!,
                            heartRate: $workoutModel.heartRate,
                            heartRateOutOfRange: $screenState.heartRateOutOfRange)
                    } else {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 70, weight: .regular)).foregroundColor(.gray)
                    }
                } else {
                    HeartRateConnectionView(state: $workoutModel.connectionState)
                }
                
                AlertView(heartRateAlert: $workoutModel.heartRateAlert, hydrationAlert: $workoutModel.hydratonAlert)
            }.padding()
            Spacer()
            VStack {
                Text("\(workoutModel.workout.currentFragment().description) for \(TimeDurationFormatter(interval: workoutModel.workout.currentFragment().duration).prettyText)")
                Spacer().frame(height: 30)
                Text("Prepare to: \(workoutModel.workout.lastFragment() ? "workout end" : workoutModel.workout.nextFragment().shortDescription) for \(workoutModel.workout.lastFragment() ? "" : TimeDurationFormatter(interval: workoutModel.workout.nextFragment().duration).prettyText)")
                    .opacity(!workoutModel.workout.lastFragment() && workoutModel.workout.currentFragment().ends(in: 5.0) ? 1 : 0)
            }.padding()
            Spacer()
            Button(action: { self.screenState.showingAlert = true }) {
                Text("End Workout").font(.system(size: 20))
            }
            .alert(isPresented: $screenState.showingAlert) {
                Alert(
                    title: Text("End this workout?"),
                    message: nil,
                    primaryButton: .destructive(Text("End Workout")) {
                        self.endWorkout()
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.workoutModel.startWorkout()
            self.workoutModel.onFinish {
                self.endWorkout()
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func endWorkout() {
        self.workoutModel.endWorkout()

        self.workoutReport.hasError  = false
        self.workoutReport.workoutId = self.workoutModel.workoutId
        self.workoutReport.startTime = self.workoutModel.startTime
        self.workoutReport.endTime   = self.workoutModel.endTime

        do {
            let data = try workoutModel.dataStore.workoutData(workoutId: self.workoutModel.workoutId)
            self.workoutReport.reportData = WorkoutReport.buildReport(data: data)
        } catch {
            self.workoutReport.hasError = true
        }
    }
    
    func validHeartRateZones(zones: [HeartRateZone]?) -> Bool {
        if let _ = zones {
            return true
        }
        return false
    }
}

class WorkoutScreenState: ObservableObject {
    @Published var heartRateOutOfRange = false
    @Published var showingAlert = false
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var plan = WorkoutPlan(
        id: 0,
        name: "Recovery",
        intervals: [
            Fragment(
                shortDescription: "Recovery",
                description: "Recovery",
                duration: infiniteDuration
            )
        ],
        hydrationReminderEnabled: false,
        heartRateAlertEnabled: false
    )
    static var monitor = createHeartRateMonitor()
    static var previews: some View {
        WorkoutScreen(workoutReport: WorkoutReport())
            .environmentObject(WorkoutModel(plan: plan, monitor: monitor))
    }
}
