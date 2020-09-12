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
    @State var screenState = WorkoutScreenState()
    
    @State var workoutId: Int = 0
    @State var fileHandle: FileHandle?
    
    @State var timer: Timer?
    @State var state: ScreenState = .ok
        
    var monitor: HeartRateProvider = createHeartRateMonitor()
    var dataStore = WorkoutDataStore()
    var alerts = AlertManager(enabled: true)
    var heartRateBlinker = Blinker()
    var hyndrationBlinker = Blinker()
    var workout: WorkoutPlan
    
    var body: some View {
        VStack {
            Text(self.state == .ok ? "Workout \(workoutId)" : "Workout can't be recoreded")
                .foregroundColor(self.state == .ok ? .black : .red)
            ElapsedTimeView(elapsed: $screenState.elapsedTime)
            Spacer()
            HStack {
                Text("\(screenState.heartRate)")
                    .font(focusedFont)
                if validHeartRateZones(zones: HeartRateZoneBuilder.allZones()) && workout.displayHeartRateZones {
                    HeartRateZonesView(zones: HeartRateZoneBuilder.allZones()!,
                        heartRate: $screenState.heartRate,
                        heartRateOutOfRange: $screenState.heartRateOutOfRange)
                } else {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 70, weight: .regular)).foregroundColor(.gray)
                }
                VStack(spacing: 30) {
                    Image(systemName: "heart.slash")
                        .opacity(self.heartRateBlinker.visible ? 1 : 0)
                        .font(.system(size: 30, weight: .regular)).foregroundColor(.red)
                    Image(systemName: "cloud.heavyrain")
                        .opacity(self.hyndrationBlinker.visible ? 1 : 0)
                        .font(.system(size: 30, weight: .regular)).foregroundColor(.blue)
                }
            }
            Spacer()
            VStack {
                Text("\(workout.currentFragment().description) for \(TimeDurationFormatter(interval: workout.currentFragment().duration).prettyText)")
                Spacer().frame(height: 30)
                Text("Prepare to: \(workout.lastFragment() ? "workout end" : workout.nextFragment().shortDescription) for \(workout.lastFragment() ? "" : TimeDurationFormatter(interval: workout.nextFragment().duration).prettyText)")
                    .opacity(!workout.lastFragment() && workout.currentFragment().ends(in: 5.0) ? 1 : 0)
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
                        self.endWorkout(screen: self)
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.screenState.elapsedTime = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                
                self.screenState.elapsedTime += 1
                self.workout.update(duration: self.screenState.elapsedTime)
                
                if self.workout.isOver() {
                    self.endWorkout(screen: self)
                    return
                }
                
                // unmute all audio reminders
                self.alerts.unmute()
                
                if self.workout.ends(in: 10.0) {
                    self.alerts.workoutEndAlert()
                    self.alerts.mute() // mute all reminders for the rest of this update
                }
                
                self.screenState.heartRate = self.monitor.getHeartRate()
                
                let currentFragment = self.workout.currentFragment()
                
                if currentFragment.recordHeartRate {
                    self.saveHeartRate(heartRate: self.screenState.heartRate, to: self.fileHandle)
                }
                
                if currentFragment.ends(in: 5.0) {
                    self.alerts.intervalEndAlert()
                    self.alerts.mute()
                }

                if self.workout.hydrationReminderEnabled {
                    let reminder = HydrationReminder(formatter: TimeDurationFormatter(interval: self.screenState.elapsedTime))
                    if reminder.hydrationDue {
                        self.alerts.hydrationAlert()
                        self.alerts.mute()
                    }
                    self.hyndrationBlinker.enabled = reminder.hydrationDue
                }
                
                if self.workout.heartRateAlertEnabled {
                    let interval = self.workout.currentFragment()
                    let eval = HeartRateEvaluator(heartRate: self.screenState.heartRate, zoneLow: interval.zone.start, zoneHigh: interval.zone.end, zoneNumber: interval.zone.number)
                    self.screenState.heartRateOutOfRange = eval.outOfRange
                    if self.screenState.heartRateOutOfRange {
                        self.alerts.heartRateAlert()
                    }
                    self.heartRateBlinker.enabled = self.screenState.heartRateOutOfRange
                }
            }
            
            let stats = self.dataStore.loadWorkoutStats()
            if stats != nil {
                self.workoutId = stats!.lastWorkoutId + 1
                let workoutStore = self.dataStore.createWorkoutSession(workoutId: self.workoutId)
                if workoutStore != nil {
                    self.fileHandle = try? FileHandle(forWritingTo: workoutStore!.dataFilePath)
                }
                self.state = workoutStore == nil ? .error : .ok
            }
            self.workoutReport.startTime = Date()
        }
        .onDisappear {
            self.timer!.invalidate()
            try? self.fileHandle?.close()
        }
    }
    
    func validHeartRateZones(zones: [HeartRateZone]?) -> Bool {
        if let _ = zones {
            return true
        }
        return false
    }
    
    func saveHeartRate(heartRate: Int, to fileHandle: FileHandle?) {
        let data = withUnsafeBytes(of: heartRate) { Data($0) }
        try? self.fileHandle?.write(contentsOf: data)
    }
    
    func endWorkout(screen: WorkoutScreen) {
        screen.workoutReport.endTime = Date()
        _ = screen.dataStore.saveWorkoutInfo(workoutId: self.workoutId, workout: WorkoutInfo(start: screen.workoutReport.startTime, end: screen.workoutReport.endTime))
        let result = screen.dataStore.lastWorkoutData()
        if let workout = result.data {
            screen.workoutReport.reportData = WorkoutReport.buildReport(data: workout)
            screen.workoutReport.workoutId = self.workoutId
        } else {
            print("error load last workout data: ", result.error)
            screen.state = .error
        }
    }
}

func createHeartRateMonitor() -> HeartRateProvider {
#if targetEnvironment(simulator)
    return HeartRateSimulator()
#else
    HeartRateMonitor()
#endif
}

struct WorkoutScreenState {
    var elapsedTime = TimeInterval()
    var heartRateOutOfRange = false
    var showingAlert = false
    var heartRate: Int = 0
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScreen(
            workoutReport: WorkoutReport(),
            alerts: AlertManager(enabled: false),
            workout: WorkoutPlan(
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
