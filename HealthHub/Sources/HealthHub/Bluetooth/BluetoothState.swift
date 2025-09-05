//
//  BluetoothState.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 03/09/2025.
//

import CoreBluetooth

/// Actor który zarządza wewnętrznym stanem Bluetooth - thread-safe z automatu
@preconcurrency
actor BluetoothState {
    
    /// Czy aktualnie skanujemy urządzenia
    var isScanning = false
    
    /// Czy Bluetooth jest włączony i gotowy do użycia
    var isPoweredOn = false
    
    /// Aktualny status systemu Bluetooth (mapowany z CBManagerState)
    var status: BluetoothStatus = .unknown
    
    var connectedPeripheral: CBPeripheral? = nil
    
    /// Thread-safe update skanowania
    func updateScanning(_ value: Bool) {
        isScanning = value
    }
    
    /// Thread-safe update stanu Bluetooth
    func updatePowerState(_ value: Bool) {
        isPoweredOn = value
    }
    
    /// Thread-safe update statusu systemu
    func updateStatus(_ newStatus: BluetoothStatus) {
        status = newStatus
        // Automatycznie aktualizuj isPoweredOn na podstawie statusu
        isPoweredOn = (newStatus == .ready)
    }
        
    func setConnectedPeripheral(_ peripheral: CBPeripheral?) {
        connectedPeripheral = peripheral
    }
}


