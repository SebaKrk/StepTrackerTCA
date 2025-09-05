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
        /// Wyciągnij wartość state lokalnie (poza Task) żeby uniknąć data races
        let cbState = central.state
        
        print("🔵 DELEGATE CALLED! CBManagerState: \(cbState)")
        
        /// Thread-safe update przez Actor + wyślij przez stream (fire and forget)
        Task { [weak self] in
            await self?.updateStatusFromCBState(cbState)
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
     
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown")")
        connectionContinuation.yield(.connected(peripheral))
    }
    
    /// DELEGATE METHOD - Wywoływane gdy nie uda się połączyć z urządzeniem
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "Unknown")")
        Task { await state.setConnectedPeripheral(nil) }
        connectionContinuation.yield(.failedToConnect(peripheral, error: error?.localizedDescription))
    }
    
    /// DELEGATE METHOD - Wywoływane gdy urządzenie się rozłączy
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from: \(peripheral.name ?? "Unknown")")
        Task { await state.setConnectedPeripheral(nil) }
        connectionContinuation.yield(.disconnected(peripheral, error: error?.localizedDescription))
    }
}
