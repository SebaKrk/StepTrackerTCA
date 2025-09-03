//
//  BluetoothState.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 03/09/2025.
//

@preconcurrency
import CoreBluetooth

/// Actor który zarządza stanem Bluetooth - thread-safe z automatu
actor BluetoothState {
    
    /// Czy aktualnie skanujemy urządzenia
    var isScanning = false
    
    /// Czy Bluetooth jest włączony i gotowy do użycia
    var isPoweredOn = false
    
    /// Thread-safe update skanowania
    func updateScanning(_ value: Bool) {
        isScanning = value
    }
    
    /// Thread-safe update stanu Bluetooth
    func updatePowerState(_ value: Bool) {
        isPoweredOn = value
    }
}
