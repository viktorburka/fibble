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
        guard let info = infoResult.info else {
            return (nil, String(format: "error load workout info file: %@", infoResult.error))
        }
        
        let dataResult = loadWorkoutData(lastWorkoutDir.appendingPathComponent("data"))
        guard let data = dataResult.data else {
            return (nil, String(format: "error load workout data file: %@", dataResult.error))
        }
        
        let workout = WorkoutData(
            id: stats.lastWorkoutId,
            start: info.startDate(),
            end: info.endDate(),
            avgHeartRate: caclulateAvgHeartRate(data)
        )
        
        return (workout, "")
    }
    
    func loadWorkoutInfo(_ url: URL) -> (info: WorkoutInfo?, error: String) {
        var jsonResult: Any
        do {
            let data = try Data(contentsOf: url)
            jsonResult = try JSONSerialization.jsonObject(with: data)
        } catch {
            return (nil, error.localizedDescription)
        }
        guard let jsonDoc = jsonResult as? Dictionary<String, Any> else {
            return (nil, "error cast json object to WorkoutData type")
        }
        guard let start = jsonDoc["start"] as? String else {
            return (nil, "error cast json object to WorkoutData type")
        }
        guard let end = jsonDoc["end"] as? String else {
            return (nil, "error cast json object to WorkoutData type")
        }
        let result = WorkoutInfo.parse(start: start, end: end)
        guard let workout = result.info else {
            return (nil, String(format: "error parse json object: %@", result.error))
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
    
    func saveWorkoutInfo(workoutId: Int, workout: WorkoutInfo) -> (success: Bool, error: String) {
        guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (false, "error find application document directory")
        }
        
        let workoutDir = docDir.appendingPathComponent(String(workoutId))
        let workoutInfoUrl = workoutDir.appendingPathComponent("info")
        print("save to: ", workoutInfoUrl)
        
        let jsonDoc: Dictionary<String, Any> = [
            "start": workout.start,
            "end": workout.end
        ]

        do {
            let fileHandle = try FileHandle(forWritingTo: workoutInfoUrl)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDoc)
            fileHandle.write(jsonData)
            try fileHandle.close()
        } catch {
            return (false, error.localizedDescription)
        }
        
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
    var id = 0
    var start = Date()
    var end = Date()
    var avgHeartRate = 0
    var calories = 0
}

struct WorkoutInfo: Codable {
    var start = String()
    var end = String()
    
    init(start: Date, end: Date) {
        let fmt = DateFormatter()
        fmt.timeStyle = .medium
        fmt.dateStyle = .medium
        self.start = fmt.string(from: start)
        self.end = fmt.string(from: end)
    }
    
    init(start: String, end: String) {
        self.start = start
        self.end = end
    }
    
    func startDate() -> Date {
        let fmt = DateFormatter()
        fmt.timeStyle = .medium
        fmt.dateStyle = .medium
        return fmt.date(from: self.start)!
    }
    
    func endDate() -> Date {
        let fmt = DateFormatter()
        fmt.timeStyle = .medium
        fmt.dateStyle = .medium
        return fmt.date(from: self.end)!
    }
    
    static func parse(start: String, end: String) -> (info: WorkoutInfo?, error: String) {
        let fmt = DateFormatter()
        fmt.timeStyle = .medium
        fmt.dateStyle = .medium
        if fmt.date(from: start) == nil {
            return (nil, "error parse 'start' element")
        }
        if fmt.date(from: end) == nil {
            return (nil, "error parse 'end' element")
        }
        return (WorkoutInfo(start: start, end: end), "")
    }
}
