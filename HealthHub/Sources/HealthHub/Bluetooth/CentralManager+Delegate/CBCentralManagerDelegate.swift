//
//  CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension DefaultCentralManager: CBCentralManagerDelegate {
    
    /// DELEGATE METHOD - System wywołuje tę funkcję gdy zmieni się stan Bluetooth
    /// Np. gdy user włączy/wyłączy Bluetooth w ustawieniach
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print("🔵 DELEGATE CALLED! State: \(central.state), isOn: \(isOn)")  
        /// Wyciągnij wartość state lokalnie (poza Task) żeby uniknąć data races
        let isOn = central.state == .poweredOn
        
        /// Thread-safe update przez Actor (bez await - fire and forget)
        Task { [weak self] in
            await self?.state.updatePowerState(isOn)
            print("🔵 Bluetooth state changed: \(isOn ? "ON" : "OFF")")
        }
    }
    
    /// DELEGATE METHOD - System wywołuje tę funkcję gdy znajdzie urządzenie podczas skanowania
    /// peripheral = znalezione urządzenie
    /// advertisementData = dane które urządzenie wysyła w reklamie
    /// RSSI = siła sygnału
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        /// Wyciągnij wartości lokalnie żeby uniknąć data races z concurrent access
        let deviceName = peripheral.name ?? "Unknown"
        let signalStrength = RSSI
        
        print("📡 Found device: \(deviceName) - RSSI: \(signalStrength)")
        
        /// KLUCZOWE: Wrzucamy znalezione urządzenie do AsyncStream
        /// Tworzymy lokalną kopię żeby uniknąć concurrent access issues
        /// CBPeripheral nie jest Sendable, ale AsyncStream radzi sobie z tym
        deviceContinuation.yield(peripheral)
    }
}
