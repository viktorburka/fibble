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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var ti = TimeInterval()
    @State private var hr = "---"
    @State var timer: Timer?
    @State var heartRate = HeartRateListener()
    @State var centralManager: CBCentralManager!
    @State private var showingAlert = false
    var body: some View {
        VStack {
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
            self.centralManager = CBCentralManager(delegate: self.heartRate, queue: nil)
            self.ti = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.ti += 1
                self.hr = String(self.heartRate.getHeartRate())
            }
        }.onDisappear {
            self.timer!.invalidate()
        }.navigationBarBackButtonHidden(true)
    }
}

struct WorkoutScreen_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScreen()
    }
}
