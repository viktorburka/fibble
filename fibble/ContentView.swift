//
//  ContentView.swift
//  fibble
//
//  Created by Viktor Burka on 8/18/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var ti = TimeInterval()
    @State private var hr = "---"
    @State var timer: Timer?
    @State var heartRate = HeartRateListener()
    @State var centralManager: CBCentralManager!
    var body: some View {
        VStack {
            Spacer()
            Text(String(format: "%02d:%02d:%02d", Int(self.ti) / 3600, Int(self.ti) / 60 % 60, Int(self.ti) % 60)).font(Font.system(size: 60).monospacedDigit())
            Spacer()
            Text("\(self.hr)").font(Font.system(size: 80).monospacedDigit())
            Spacer()
            Text("Laps").font(.system(size: 60))
            Spacer()
            Button(action: {
                print("end workout")
            }) {
                Text("End Workout").font(.system(size: 20))
            }
            Spacer()
        }.onAppear {
            self.centralManager = CBCentralManager(delegate: self.heartRate, queue: nil)
            self.ti = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.ti += 1
                self.hr = String(self.heartRate.getHeartRate())
            }
        }.onDisappear {
            self.timer!.invalidate()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
