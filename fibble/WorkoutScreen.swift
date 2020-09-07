//
//  WorkoutScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/21/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI
import CoreBluetooth

let focusedFont = Font.system(size: 100).monospacedDigit()

struct WorkoutScreen: View {
    @State var store = WorkoutDataStore()
    @State var heartRateListener = HeartRateListener()
    @State var centralManager: CBCentralManager? = nil
    @State var workoutId: Int = 0
    @State var heartRate: Int = 0
    @State var fileHandle: FileHandle?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var timeInterval = TimeInterval()
    @State var timer: Timer?
    @State var showingAlert = false
    @State var state: ScreenState = .ok
    @State var zones: [Zone] = []
    @State var startTime = Date()
    @State var endTime = Date()
    @State var heartRateOutOfRange = false
    @ObservedObject var lastReport: WorkoutReport
    var workout: Workout
    var alerts = AlertManager(enabled: true)
    var heartRateBlinker = Blinker()
    var hyndrationBlinker = Blinker()
    var body: some View {
        VStack {
            Text(self.state == .ok ? "Workout \(workoutId)" : "Workout can't be recoreded")
                .foregroundColor(self.state == .ok ? .black : .red)
            Text(String(format: "%02d:%02d:%02d", Int(self.timeInterval) / 3600, Int(self.timeInterval) / 60 % 60, Int(self.timeInterval) % 60)).font(Font.system(size: 80).monospacedDigit())
            Spacer()
            HStack {
                Text("\(heartRate)").font(focusedFont)
                VStack(alignment: .leading) {
                    ForEach(zones) { z in
                        Text(String(format: "Z%d  %d-%d", z.number, z.start, z.end))
                            .opacity(z.highlighted ? 1 : 0)
                            .foregroundColor(self.heartRateOutOfRange ? .red : .black)
                    }
                }
                .font(Font.system(size: 18).bold())
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
            //Text("Laps").font(.system(size: 60))
            Text(workout.currentInterval().description)
//            Spacer().frame(height: 10)
            Text("Prepare to: \(workout.lastInterval() ? "" : workout.nextInterval().shortDescription) for \(workout.lastInterval() ? "" : TimeDurationFormatter(interval: workout.nextInterval().duration).prettyText)")
                .opacity(!workout.lastInterval() && workout.intervalEnds(in: 5.0) ? 1 : 0)
            Spacer()
            Button(action: { self.showingAlert = true }) {
                Text("End Workout").font(.system(size: 20))
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("End this workout?"),
                    message: nil,
                    primaryButton: .destructive(Text("End Workout")) {
                        self.endTime = Date()
                        _ = self.store.saveWorkoutInfo(workoutId: self.workoutId, workout: WorkoutInfo(start: self.startTime, end: self.endTime))
                        let result = self.store.lastWorkoutData()
                        if let workout = result.data {
                            self.lastReport.reportData = WorkoutReport.buildReport(data: workout)
                            self.lastReport.workoutId = self.workoutId
                        } else {
                            print("error load last workout data: ", result.error)
                            self.state = .error
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.zones.removeAll()
            for hrz in 1...5 {
                let z = HeartRateZoneBuilder.byNumber(number: hrz)
                self.zones.append(Zone(number: z.number, start: z.start, end: z.end, highlighted: false))
            }
            if self.zones.count > 0 {
                self.zones[0].highlighted = true
            }
            self.timeInterval = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.timeInterval += 1
                self.workout.setElapsed(duration: self.timeInterval)
                self.heartRate = self.heartRateListener.getHeartRate()
                for idx in 0...self.zones.count-1 {
                    self.zones[idx].updateHighlighting(heartRate: self.heartRate)
                }
                if self.fileHandle != nil {
                    let data = withUnsafeBytes(of: self.heartRate) { Data($0) }
                    try? self.fileHandle!.write(contentsOf: data)
                }
                if self.workout.intervalEnds(in: 5.0) {
                    self.alerts.intervalChangeAlert()
                }
                if self.workout.hydrationReminderEnabled {
                    let reminder = HydrationReminder(formatter: TimeDurationFormatter(interval: self.timeInterval))
                    if reminder.hydrationDue {
                        self.alerts.hydrationAlert()
                    }
                    self.hyndrationBlinker.enabled = reminder.hydrationDue
                    
                    if self.workout.heartRateAlertEnabled {
                        let interval = self.workout.currentInterval()
                        let eval = HeartRateEvaluator(heartRate: self.heartRate, zoneLow: interval.zone.start, zoneHigh: interval.zone.end, zoneNumber: interval.zone.number)
                        self.heartRateOutOfRange = eval.outOfRange
                        if self.heartRateOutOfRange && !reminder.hydrationDue {
                            self.alerts.heartRateAlert()
                        }
                        self.heartRateBlinker.enabled = self.heartRateOutOfRange
                    }
                }
            }
            
            self.centralManager = CBCentralManager(delegate: self.heartRateListener, queue: nil)
            
            let stats = self.store.loadWorkoutStats()
            if stats != nil {
                self.workoutId = stats!.lastWorkoutId + 1
                let workoutStore = self.store.createWorkoutSession(workoutId: self.workoutId)
                if workoutStore != nil {
                    self.fileHandle = try? FileHandle(forWritingTo: workoutStore!.dataFilePath)
                }
                self.state = workoutStore == nil ? .error : .ok
            }
            self.startTime = Date()
        }
        .onDisappear {
            print("disappear")
            self.timer!.invalidate()
            try? self.fileHandle?.close()
        }
    }
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScreen(
            lastReport: WorkoutReport(),
            workout: Workout(id: 1, name: "Recovery", intervals: [Recovery()]),
            alerts: AlertManager(enabled: false)
        )
    }
}
