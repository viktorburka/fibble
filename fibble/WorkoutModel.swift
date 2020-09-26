//
//  WorkoutModel.swift
//  fibble
//
//  Created by Viktor Burka on 9/13/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class WorkoutModel: ObservableObject {
    @Published var elapsedTime = TimeInterval()
    @Published var heartRate = 0
    @Published var hydratonAlert = false
    @Published var heartRateAlert = false
    @Published var error = WorkoutError.none
    @Published var connectionState = HeartRateProviderState.powerOff
    @Published var pulse = false
    
    var workout: WorkoutPlan
    var monitor: HeartRateProvider
    
    var timer: Timer? = nil
    var dataStore: WorkoutDataStore = LocalFileStore()
    var alerts = AlertManager()
    
    var blockTimer = false
    var startTime = Date()
    var endTime = Date()
    var workoutId = 0
    
    var finishHandlers = [() -> Void]()
    
    enum WorkoutError {
        case none
        case dataStoreError
    }
    
    init(plan: WorkoutPlan, monitor: HeartRateProvider) {
        self.workout = plan
        self.monitor = monitor
        self.connectionState = monitor.state()
    }
    
    func startWorkout() {
        // reset state
        startTime   = Date()
        elapsedTime = 0
        blockTimer  = false
        
        // create workout entry in data store
        startWorkoutDataStoreSession()
        
        if monitor.state() != HeartRateProviderState.ready {
            monitor.connectSensor { state in
                self.connectionState = state
            }
        }
        
        // connect heart rate sensor
        monitor.listen() { heartRate in
            self.heartRate = heartRate
            self.pulse = !self.pulse
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.blockTimer {
                return
            }
            
            self.elapsedTime += 1
            self.workout.update(duration: self.elapsedTime)
            
            if self.workout.isOver() {
                self.endWorkout()
                self.execFinishHandlers()
                return
            }
            
            self.recordHeartRate()
            self.updateHydrationAlert()
            self.updateHeartRateAlert()
        }
    }
    
    func onFinish(handler: @escaping () -> Void) {
        finishHandlers.append(handler)
    }
    
    func execFinishHandlers() {
        for handler in finishHandlers {
            handler()
        }
    }
        
    func recordHeartRate() {
        let currentFragment = self.workout.currentFragment()
        if currentFragment.recordHeartRate {
            do {
                try self.dataStore.saveHeartRate(heartRate: self.heartRate)
            } catch {
                self.error = .dataStoreError
            }
        }
    }
    
    func updateHydrationAlert() {
        if self.workout.hydrationReminderEnabled {
            let remindEvery = 15 * 60 // 15 min
            let duration = 20 // sec
            self.hydratonAlert = Int(self.elapsedTime) % remindEvery < duration
        }
        if self.hydratonAlert {
            self.alerts.hydrationAlert()
        }
    }
    
    func updateHeartRateAlert() {
        if self.workout.heartRateAlertEnabled {
            let zone = self.workout.currentFragment().zone
            var enable = false
            if self.heartRate < zone.start && zone.number != 1 {
                enable = true
            }
            else if self.heartRate > zone.end {
                enable = true
            }
            self.heartRateAlert = enable
        }
        if self.heartRateAlert {
            self.alerts.heartRateAlert()
        }
    }
    
    func endWorkout() {
        endTime    = Date()
        blockTimer = true
        self.timer?.invalidate()
        do {
            try dataStore.saveWorkoutInfo(info: WorkoutInfo(start: startTime, end: endTime))
            try dataStore.finishWorkout()
        } catch {
            self.error = .dataStoreError
        }
    }
    
    private func startWorkoutDataStoreSession() {
        do {
            self.workoutId = try self.dataStore.startWorkout()
        } catch {
            self.error = .dataStoreError
        }
    }
}

