//
//  DefaultCentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth

final class DefaultCentralManager: NSObject, CentralManager {
    
    let cbCentralManager: CBCentralManager
    
    var connectedPeripheral: CBPeripheral?
    var discoveredPeripherals: [CBPeripheral] = []
    
    var isPoweredOn = false
    var isScanning = false
    
    override init() {
        self.cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        self.cbCentralManager.delegate = self
    }
    
    public func startScanning() {
        guard isPoweredOn else {
            return
        }
        cbCentralManager.scanForPeripherals(withServices: [Gatt.Service.heartRate])
        isScanning = true
    }
    
    public func stopScanning() {
        cbCentralManager.stopScan()
        isScanning = false
        discoveredPeripherals = []
    }
    
    func connect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        cbCentralManager.connect(peripheral)
        stopScanning()
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            return
        }
        cbCentralManager.cancelPeripheralConnection(peripheral)
        connectedPeripheral = nil
    }
    
}
