//
//  CentralManager+CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth

extension DefaultCentralManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripheral.delegate = self
        peripheral.discoverServices([Gatt.Service.heartRate])
    }
    
}
