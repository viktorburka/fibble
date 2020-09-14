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
    
    var workout: WorkoutPlan
    
    var timer: Timer? = nil
    var monitor: HeartRateProvider = createHeartRateMonitor()
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
    
    init(plan: WorkoutPlan) {
        self.workout = plan
    }
    
    func startWorkout() {
        // reset state
        startTime   = Date()
        elapsedTime = 0
        blockTimer  = false
        
        // create workout entry in data store
        startWorkoutDataStoreSession()
        
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
            
            self.updateHeartRate()
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
    
    func updateHeartRate() {
        self.heartRate = self.monitor.getHeartRate()
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

func createHeartRateMonitor() -> HeartRateProvider {
#if targetEnvironment(simulator)
    return HeartRateSimulator()
#else
    return HeartRateMonitor()
#endif
}
