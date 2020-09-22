//
//  HeartRateMonitor.swift
//  fibble
//
//  Created by Viktor Burka on 9/10/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import Foundation
import CoreBluetooth

enum HeartRateProviderState {
    case powerOff, powerOn, scan, connect, discoverServices, discoverCharacteristics, ready
}

protocol HeartRateProvider {
    func connectSensor(handler: @escaping (HeartRateProviderState) -> Void)
    func listen(handler: @escaping (Int) -> Void)
    func state() -> HeartRateProviderState
}

class HeartRateMonitor: NSObject, HeartRateProvider, CBCentralManagerDelegate, CBPeripheralDelegate {
    let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    
    var centralManager: CBCentralManager?
    var heartRateSensor: CBPeripheral!
    var deviceState = HeartRateProviderState.powerOff
    
    var stateChangeHandlers = [(HeartRateProviderState) -> Void]()
    var heartRateUpdateHandlers = [(Int) -> Void]()
    
    func connectSensor(handler: @escaping (HeartRateProviderState) -> Void) {
        stateChangeHandlers.append(handler)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func listen(handler: @escaping (Int) -> Void) {
        print("add listen handler")
        heartRateUpdateHandlers.append(handler)
    }
    
    func state() -> HeartRateProviderState {
        return self.deviceState
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
            updateState(state: HeartRateProviderState.powerOff)
          case .poweredOn:
            print("central.state is .poweredOn")
            updateState(state: HeartRateProviderState.powerOn)
            central.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            updateState(state: HeartRateProviderState.scan)
        @unknown default:
            print("error: unknown manager state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == "TICKR CBA5" {
            self.heartRateSensor = peripheral
            self.heartRateSensor.delegate = self
            central.stopScan()
            central.connect(heartRateSensor)
            updateState(state: HeartRateProviderState.connect)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        heartRateSensor.discoverServices([heartRateServiceCBUUID])
        updateState(state: HeartRateProviderState.discoverServices)
    }
    
    private func updateState(state: HeartRateProviderState) {
        self.deviceState = state
        for handler in stateChangeHandlers {
            handler(state)
        }
    }
    
    private func updateHeartRate(value: Int) {
        self.currentHeartRate = value
        print("updateHeartRate:", value)
        for handler in heartRateUpdateHandlers {
            print("call handler")
            handler(value)
        }
    }
    
    // sensor delegate
    let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    var currentHeartRate = 0
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicCBUUID], for: service)
            updateState(state: HeartRateProviderState.discoverCharacteristics)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                updateState(state: HeartRateProviderState.ready)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
      switch characteristic.uuid {
        case heartRateMeasurementCharacteristicCBUUID:
            let bpm = heartRate(from: characteristic)
            print("bpm:", bpm)
            self.updateHeartRate(value: bpm)
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        // Heart Rate Value Format is in the 2nd byte
        return Int(byteArray[1])
      } else {
        // Heart Rate Value Format is in the 2nd and 3rd bytes
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }
}

class HeartRateSimulator: HeartRateProvider {
    //var values = [80, 82, 85, 88, 90, 91, 92, 95, 97, 99, 100, 105, 106, 108, 111, 115, 118, 121, 125]
    var sendHeartRate = false
    
    func connectSensor(handler: @escaping (HeartRateProviderState) -> Void) {
        let states = [
            HeartRateProviderState.powerOff,
            HeartRateProviderState.powerOn,
            HeartRateProviderState.scan,
            HeartRateProviderState.connect,
            HeartRateProviderState.discoverServices,
            HeartRateProviderState.discoverCharacteristics,
            HeartRateProviderState.ready
        ]
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if index == states.count {
                self.sendHeartRate = true
                timer.invalidate()
                return
            } else {
                handler(states[index])
                index += 1
            }
        }
    }
    
    func listen(handler: @escaping (Int) -> Void) {
        let values = [80, 130, 140, 141, 142, 143]
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !self.sendHeartRate {
                return
            }
            handler(values[index % values.count])
            index += 1
        }
    }
    
    func state() -> HeartRateProviderState {
        return HeartRateProviderState.ready
    }
}
