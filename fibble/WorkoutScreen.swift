//
//  WorkoutScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/21/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

let focusedFont = Font.system(size: 100).monospacedDigit()

struct WorkoutScreen: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var workoutReport: WorkoutReport
    @ObservedObject var screenState = WorkoutScreenState()
    var workoutPlan: WorkoutPlan
    
    var body: some View {
        VStack {
//            Text(self.state == .ok ? "Workout \(workoutId)" : "Workout can't be recoreded")
//                .foregroundColor(self.state == .ok ? .black : .red)
            ElapsedTimeView(elapsed: $screenState.elapsedTime)
//            Text(String(format: "%02d:%02d:%02d", Int(self.screenState.elapsed) / 3600, Int(self.screenState.elapsed) / 60 % 60, Int(self.screenState.elapsed) % 60))
                .font(Font.system(size: 80).monospacedDigit())
            Spacer()
            HStack {
                Text("\(screenState.heartRate)")
                    .font(focusedFont)
                if validHeartRateZones(zones: HeartRateZoneBuilder.allZones()) && screenState.workout.displayHeartRateZones {
                    HeartRateZonesView(zones: HeartRateZoneBuilder.allZones()!,
                        heartRate: $screenState.heartRate,
                        heartRateOutOfRange: $screenState.heartRateOutOfRange)
                } else {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 70, weight: .regular)).foregroundColor(.gray)
                }
                VStack(spacing: 30) {
                    Image(systemName: "heart.slash")
                        .opacity(self.screenState.heartRateBlinker.visible ? 1 : 0)
                        .font(.system(size: 30, weight: .regular)).foregroundColor(.red)
                    Image(systemName: "cloud.heavyrain")
                        .opacity(self.screenState.hyndrationBlinker.visible ? 1 : 0)
                        .font(.system(size: 30, weight: .regular)).foregroundColor(.blue)
                }
            }
            Spacer()
            VStack {
                Text("\(screenState.workout.currentFragment().description) for \(TimeDurationFormatter(interval: screenState.workout.currentFragment().duration).prettyText)")
                Spacer().frame(height: 30)
                Text("Prepare to: \(screenState.workout.lastFragment() ? "workout end" : screenState.workout.nextFragment().shortDescription) for \(screenState.workout.lastFragment() ? "" : TimeDurationFormatter(interval: screenState.workout.nextFragment().duration).prettyText)")
                    .opacity(!screenState.workout.lastFragment() && screenState.workout.currentFragment().ends(in: 5.0) ? 1 : 0)
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
            self.screenState.workout = self.workoutPlan
            self.screenState.startWorkout()
        }
    }
    
    func endWorkout() {
        do {
            try self.screenState.endWorkout()
            
            self.workoutReport.workoutId = self.screenState.workoutId
            self.workoutReport.startTime = self.screenState.startTime
            self.workoutReport.endTime = self.screenState.endTime
            
            let data = try screenState.dataStore.workoutData(workoutId: self.screenState.workoutId)
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

func createHeartRateMonitor() -> HeartRateProvider {
#if targetEnvironment(simulator)
    return HeartRateSimulator()
#else
    return HeartRateMonitor()
#endif
}

enum WorkoutScreenError {
    case none
    case dataStoreError
}

class WorkoutScreenState: ObservableObject {
    // visual
    @Published var elapsedTime = TimeInterval()
    @Published var heartRateOutOfRange = false
    @Published var showingAlert = false
    @Published var heartRate: Int = 0
    @Published var error = WorkoutScreenError.none
    
    // non visual
    var timer: Timer? = nil
    var monitor: HeartRateProvider = createHeartRateMonitor()
    var dataStore: WorkoutDataStore = LocalFileStore()
    var alerts = AlertManager(enabled: true)
    var heartRateBlinker = Blinker()
    var hyndrationBlinker = Blinker()
    var workout = WorkoutPlan()
    var blockTimer = false
    var startTime = Date()
    var endTime = Date()
    var workoutId = 0
    
    func startWorkout() {
        startTime = Date()
        elapsedTime = 0
        do {
            self.workoutId = try self.dataStore.startWorkout()
        } catch {
            self.error = .dataStoreError
        }
        
        self.blockTimer = false
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.blockTimer {
                return
            }
            print("timer tick", self.elapsedTime)
            self.elapsedTime += 1
            self.workout.update(duration: self.elapsedTime)
            
            if self.workout.isOver() {
                try? self.endWorkout()
                return
            }
            
            // unmute all audio reminders
            self.alerts.unmute()
            
            if self.workout.ends(in: 10.0) {
                self.alerts.workoutEndAlert()
                self.alerts.mute() // mute all reminders for the rest of this update
            }
            
            self.heartRate = self.monitor.getHeartRate()
            
            let currentFragment = self.workout.currentFragment()
            
            if currentFragment.recordHeartRate {
                do {
                    try self.dataStore.saveHeartRate(heartRate: self.heartRate)
                } catch {
                    self.error = .dataStoreError
                }
            }
            
            if currentFragment.ends(in: 5.0) {
                self.alerts.intervalEndAlert()
                self.alerts.mute()
            }

            if self.workout.hydrationReminderEnabled {
                let reminder = HydrationReminder(formatter: TimeDurationFormatter(interval: self.elapsedTime))
                if reminder.hydrationDue {
                    self.alerts.hydrationAlert()
                    self.alerts.mute()
                }
                self.hyndrationBlinker.enabled = reminder.hydrationDue
            }
            
            if self.workout.heartRateAlertEnabled {
                let interval = self.workout.currentFragment()
                let eval = HeartRateEvaluator(heartRate: self.heartRate, zoneLow: interval.zone.start, zoneHigh: interval.zone.end, zoneNumber: interval.zone.number)
                self.heartRateOutOfRange = eval.outOfRange
                if self.heartRateOutOfRange {
                    self.alerts.heartRateAlert()
                }
                self.heartRateBlinker.enabled = self.heartRateOutOfRange
            }
        }
    }
    
    func endWorkout() throws {
        endTime = Date()
        blockTimer = true
        self.timer?.invalidate()
        try dataStore.saveWorkoutInfo(info: WorkoutInfo(start: startTime, end: endTime))
        try dataStore.finishWorkout()
    }
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScreen(
            workoutReport: WorkoutReport(),
            workoutPlan: WorkoutPlan(
                id: 0,
                name: "Recovery",
                intervals: [
                    Fragment(
                        shortDescription: "Recovery",
                        description: "Recovery",
                        duration: infiniteDuration
                    )
                ]
            )
        )
    }
}
