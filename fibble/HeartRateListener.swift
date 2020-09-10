//
//  HeartRateListener.swift
//  fibble
//
//  Created by Viktor Burka on 8/20/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import CoreBluetooth

class HeartRateListener: NSObject, CBCentralManagerDelegate {
    
    let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    let heartRateSensorDelegate = HeartRateSensorDelegate()
    
    var heartRateSensor: CBPeripheral!
    
    func getHeartRate() -> Int {
        return self.heartRateSensorDelegate.currentHeartRate
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            central.scanForPeripherals(withServices: [heartRateServiceCBUUID])
        @unknown default:
            print("error: unknown manager state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == "TICKR CBA5" {
            print(peripheral)
            self.heartRateSensor = peripheral
            self.heartRateSensor.delegate = self.heartRateSensorDelegate
            central.stopScan()
            central.connect(heartRateSensor)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        heartRateSensor.discoverServices([heartRateServiceCBUUID])
    }
}
