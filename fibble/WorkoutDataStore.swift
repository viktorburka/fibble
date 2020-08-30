//
//  WorkoutDataStore.swift
//  fibble
//
//  Created by Viktor Burka on 8/22/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

class WorkoutDataStore {
    let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func loadWorkoutStats() -> WorkoutStats? {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let workouts = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        if workouts == nil {
            return nil
        }
        
        var lastIdx = 0
        
        for workout in workouts! {
            let id = Int(workout.lastPathComponent) ?? 0
            if id > lastIdx {
                lastIdx = id
            }
        }
        
        return WorkoutStats(lastWorkoutId: lastIdx)
    }
    
    func createWorkoutSession(workoutId: Int) -> WorkoutStore? {
        guard let rootUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let nextWorkoutDir = rootUrl.appendingPathComponent(String(workoutId))
        let workoutDataFilePath = nextWorkoutDir.appendingPathComponent("data")
        let workoutInfoFilePath = nextWorkoutDir.appendingPathComponent("info")
        
        do {
            try fileManager.createDirectory(at: nextWorkoutDir, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("error create workout \(workoutId) directory: \(error)")
            return nil
        }
        
        if !fileManager.createFile(atPath: workoutDataFilePath.path, contents: nil, attributes: nil) {
            print("can't create file \(workoutDataFilePath.lastPathComponent)")
            return nil
        }
        
        if !fileManager.createFile(atPath: workoutInfoFilePath.path, contents: nil, attributes: nil) {
            print("can't create file \(workoutInfoFilePath.lastPathComponent)")
            return nil
        }
        
        return WorkoutStore(dataFilePath: workoutDataFilePath, folder: nextWorkoutDir)
    }
    
    func lastWorkoutData() -> (data: WorkoutData?, error: String) {
        guard let stats = loadWorkoutStats() else {
            return (nil, "error find last workout id")
        }
        
        guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (nil, "error find application document directory")
        }
        
        let lastWorkoutDir = docDir.appendingPathComponent(String(stats.lastWorkoutId))
        
        let infoResult = loadWorkoutInfo(lastWorkoutDir.appendingPathComponent("info"))
        guard let workout = infoResult.info else {
            return (nil, String(format: "error load workout info file: %s", infoResult.error))
        }
        
        let dataResult = loadWorkoutData(lastWorkoutDir.appendingPathComponent("data"))
        guard let data = dataResult.data else {
            return (nil, String(format: "error load workout info file: %s", dataResult.error))
        }
        
        var copy = workout
        copy.avgHeartRate = caclulateAvgHeartRate(data)
        
        return (copy, "")
    }
    
    func loadWorkoutInfo(_ url: URL) -> (info: WorkoutData?, error: String) {
        var jsonResult: Any
        do {
            let data = try Data(contentsOf: url)
            jsonResult = try JSONSerialization.jsonObject(with: data)
        } catch {
            return (nil, error.localizedDescription)
        }
        guard let workout = jsonResult as? WorkoutData else {
            return (nil, "error cast json object to WorkoutData type")
        }
        return (workout, "")
    }
    
    func loadWorkoutData(_ url: URL) -> (data: [Int]?, error: String) {
        var data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return (nil, error.localizedDescription)
        }
        let intOpt = dataToIntArr(data: data) as [Int]?
        return (intOpt, "")
    }
    
    func caclulateAvgHeartRate(_ data: [Int]) -> Int {
        var sum = 0
        for d in data {
            sum += d
        }
        return data.count != 0 ? sum / data.count : 0
    }
    
    func saveWorkoutData(workoutId: Int, start: Date, end: Date) -> (success: Bool, error: String) {
        guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (false, "error find application document directory")
        }
        
        let workoutDir = docDir.appendingPathComponent(String(workoutId))
        
        //workoutDir.appendingPathComponent("info")
        
        //let workout = WorkoutData(start: start, end: end)
        // save to json
        
        return (true, "")
    }
}

class WorkoutStats {
    var lastWorkoutId: Int
    init(lastWorkoutId: Int) {
        self.lastWorkoutId = lastWorkoutId
    }
}

class WorkoutStore {
    var dataFilePath: URL
    var folder: URL
    init(dataFilePath: URL, folder: URL) {
        self.dataFilePath = dataFilePath
        self.folder = folder
    }
}

struct WorkoutData {
    var start = Date()
    var end = Date()
    var avgHeartRate = 0
    var calories = 0
}
