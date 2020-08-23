//
//  WorkoutScreen.swift
//  fibble
//
//  Created by Viktor Burka on 8/21/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI
import CoreBluetooth

struct WorkoutScreen: View {
    var store: WorkoutDataStore
    @State var workoutId: Int = 0
    @State var fileHandle: FileHandle?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var ti = TimeInterval()
    @State var hr = "127"
    @State var timer: Timer?
    @State var heartRate = HeartRateListener()
    @State var centralManager: CBCentralManager!
    @State var showingAlert = false
    @State var state: MainScreenState = .ok
    var body: some View {
        VStack {
            Text(self.state == .ok ? "Workout \(workoutId)" : "Workout can't be recoreded")
                .foregroundColor(self.state == .ok ? .black : .red)
//            Spacer().frame(height: 10)
            Text(String(format: "%02d:%02d:%02d", Int(self.ti) / 3600, Int(self.ti) / 60 % 60, Int(self.ti) % 60)).font(Font.system(size: 80).monospacedDigit())
            Spacer()
            Text("\(self.hr)").font(Font.system(size: 140).monospacedDigit())
            Spacer()
            Text("Laps").font(.system(size: 60))
            Spacer()
            Button(action: {
                self.showingAlert = true
                print("end workout")
            }) {
                Text("End Workout").font(.system(size: 20))
            }.alert(isPresented: $showingAlert) {
                Alert(title: Text("End this workout?"), message: nil, primaryButton: .destructive(Text("End Workout")) {
                        self.presentationMode.wrappedValue.dismiss()
                }, secondaryButton: .cancel())
            }
            Spacer()
        }.onAppear {
            let stats = self.store.loadWorkoutStats()
            if stats != nil {
                self.workoutId = stats!.lastWorkoutId + 1
                let workoutStore = self.store.createWorkoutSession(workoutId: self.workoutId)
                if workoutStore == nil {
                    self.state = .error
                } else {
                    self.state = .ok
                    do {
                        try self.fileHandle = FileHandle(forWritingTo: workoutStore!.dataFilePath)
                    } catch {
                        print("can't init file handle: \(error)")
                    }
                }
            }
            self.centralManager = CBCentralManager(delegate: self.heartRate, queue: nil)
            self.ti = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.ti += 1
                let heartRate = self.heartRate.getHeartRate()
                self.hr = String(heartRate)
                if self.fileHandle != nil {
                    let data = withUnsafeBytes(of: heartRate) { Data($0) }
                    do {
                        try self.fileHandle!.write(contentsOf: data)
                    } catch {
                        print("error write heart rate data: \(error)")
                    }
                    print("heart rate saved")
                }
            }
        }.onDisappear {
            self.timer!.invalidate()
            do {
                try self.fileHandle?.close()
            } catch {
                print("error close file: \(error)")
            }
        }.navigationBarBackButtonHidden(true)
    }
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScreen(store: WorkoutDataStore())
    }
}
