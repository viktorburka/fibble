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
        
        return WorkoutStore(dataFilePath: workoutDataFilePath, folder: nextWorkoutDir)
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
