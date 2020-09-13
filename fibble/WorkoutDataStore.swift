//
//  WorkoutDataStore.swift
//  fibble
//
//  Created by Viktor Burka on 8/22/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation

protocol WorkoutDataStore {
    func startWorkout() throws -> Int
    func saveHeartRate(heartRate: Int) throws
    func saveWorkoutInfo(info: WorkoutInfo) throws
    func finishWorkout() throws
    func workoutData(workoutId: Int) throws -> WorkoutData
    func loadWorkoutStats() throws -> WorkoutStats
}

enum WorkoutStoreError: Error {
    case activeWorkoutExists
    case documentDirAccessIssue
    case ioError
    case noWorkoutFound
    case jsonError
    case dataError
}

class LocalFileStore: WorkoutDataStore {
    let fileManager = FileManager.default
    var dataFileHandle: FileHandle? = nil
    var infoFileHandle: FileHandle? = nil
    
    func startWorkout() throws -> Int {
        if dataFileHandle != nil {
            throw WorkoutStoreError.activeWorkoutExists
        }
        
        guard let rootUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw WorkoutStoreError.documentDirAccessIssue
        }
        
        let workoutStats = try loadWorkoutStats()
        let nextWorkoutId = workoutStats.lastWorkoutId+1
        let nextWorkoutDir = rootUrl.appendingPathComponent(String(nextWorkoutId))
        let workoutDataFilePath = nextWorkoutDir.appendingPathComponent("data")
        let workoutInfoFilePath = nextWorkoutDir.appendingPathComponent("info")
        
        do {
            try fileManager.createDirectory(at: nextWorkoutDir, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("i/o error: \(error)")
            throw WorkoutStoreError.ioError
        }
        
        // create heart rate data file
        if !fileManager.createFile(atPath: workoutDataFilePath.path, contents: nil, attributes: nil) {
            print("can't create file \(workoutDataFilePath.lastPathComponent)")
            throw WorkoutStoreError.ioError
        }
        
        // create workout info file
        if !fileManager.createFile(atPath: workoutInfoFilePath.path, contents: nil, attributes: nil) {
            print("can't create file \(workoutInfoFilePath.lastPathComponent)")
            throw WorkoutStoreError.ioError
        }
        
        dataFileHandle = try FileHandle(forWritingTo: workoutDataFilePath)
        infoFileHandle = try FileHandle(forWritingTo: workoutInfoFilePath)
        
        return nextWorkoutId
    }
    
    func saveHeartRate(heartRate: Int) throws {
        guard let file = dataFileHandle else {
            throw WorkoutStoreError.noWorkoutFound
        }
        let data = withUnsafeBytes(of: heartRate) { Data($0) }
        try file.write(contentsOf: data)
    }
    
    func saveWorkoutInfo(info: WorkoutInfo) throws {
        guard let file = infoFileHandle else {
            throw WorkoutStoreError.noWorkoutFound
        }
        
        let jsonDoc: Dictionary<String, Any> = [
            "start": info.start,
            "end": info.end
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDoc)
            file.write(jsonData)
            try file.close()
        } catch {
            throw WorkoutStoreError.ioError
        }
    }
    
    func workoutData(workoutId: Int) throws -> WorkoutData {
        guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw WorkoutStoreError.documentDirAccessIssue
        }
        
        let workoutDir = docDir.appendingPathComponent(String(workoutId))
        let info = try loadWorkoutInfo(workoutDir.appendingPathComponent("info"))
        
        guard let data = try loadWorkoutData(workoutDir.appendingPathComponent("data")) else {
            throw WorkoutStoreError.dataError
        }
        
        let workout = WorkoutData(
            id: workoutId,
            start: info.startDate(),
            end: info.endDate(),
            avgHeartRate: caclulateAvgHeartRate(data)
        )
        
        return workout
    }
    
    func finishWorkout() throws {
        guard let dataFile = dataFileHandle else {
            throw WorkoutStoreError.ioError
        }
        guard let infoFile = infoFileHandle else {
            throw WorkoutStoreError.ioError
        }
        
        try dataFile.close()
        dataFileHandle = nil
        
        try infoFile.close()
        infoFileHandle = nil
    }
    
    func loadWorkoutStats() throws -> WorkoutStats {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw WorkoutStoreError.documentDirAccessIssue
        }
        
        let workouts = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        var lastIdx = 0
        for workout in workouts {
            let id = Int(workout.lastPathComponent) ?? 0
            if id > lastIdx {
                lastIdx = id
            }
        }
        
        return WorkoutStats(lastWorkoutId: lastIdx)
    }
    
    private func loadWorkoutInfo(_ url: URL) throws -> WorkoutInfo {
        var jsonResult: Any
        do {
            let data = try Data(contentsOf: url)
            jsonResult = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw WorkoutStoreError.jsonError
        }
        guard let jsonDoc = jsonResult as? Dictionary<String, Any> else {
            throw WorkoutStoreError.jsonError
        }
        guard let start = jsonDoc["start"] as? String else {
            throw WorkoutStoreError.jsonError
        }
        guard let end = jsonDoc["end"] as? String else {
            throw WorkoutStoreError.jsonError
        }
        guard let info = WorkoutInfo.parse(start: start, end: end) else {
            throw WorkoutStoreError.jsonError
        }
        return info
    }
    
    private func loadWorkoutData(_ url: URL) throws -> [Int]? {
        let data = try Data(contentsOf: url)
        let intOpt = dataToIntArr(data: data) as [Int]?
        return intOpt
    }
    
    private func caclulateAvgHeartRate(_ data: [Int]) -> Int {
        var sum = 0
        for d in data {
            sum += d
        }
        return data.count != 0 ? sum / data.count : 0
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
    
    static func parse(start: String, end: String) -> WorkoutInfo? {
        let fmt = DateFormatter()
        fmt.timeStyle = .medium
        fmt.dateStyle = .medium
        if fmt.date(from: start) == nil {
            return nil
        }
        if fmt.date(from: end) == nil {
            return nil
        }
        return WorkoutInfo(start: start, end: end)
    }
}
