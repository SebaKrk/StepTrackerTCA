//
//  CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension DefaultCentralManager: CBCentralManagerDelegate {
    
    /// DELEGATE METHOD - System wywołuje tę funkcję gdy zmieni się stan Bluetooth
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let cbState = central.state
        print("🔵 DELEGATE CALLED! CBManagerState: \(cbState)")
        
        /// Thread-safe update przez Actor (fire and forget)
        Task { [weak self] in
            await self?.updateStatusFromCBState(cbState)
        }
    }
    
    /// DELEGATE METHOD - System wywołuje tę funkcję gdy znajdzie urządzenie podczas skanowania
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let deviceName = peripheral.name ?? "Unknown"
        let signalStrength = RSSI
        
        print("📡 Found device: \(deviceName) - RSSI: \(signalStrength)")
        
        /// KLUCZOWE: Wrzucamy znalezione urządzenie do aktora
        Task { [weak self] in
            await self?.state.yieldDevice(peripheral)
        }
    }
    
    /// DELEGATE METHOD - Wywoływane gdy urządzenie się pomyślnie połączy
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown")")
        print("📱 Setting peripheral in BluetoothState...")
        
        // DODAJ: Ustaw delegate i service discovery
        peripheral.delegate = self
        peripheral.discoverServices([Gatt.Service.heartRate])
        print("🔍 Starting service discovery...")
        
        Task { [weak self] in
            await self?.state.setConnectedPeripheral(peripheral)
            let saved = await self?.state.connectedPeripheral
            print("📱 Verified saved peripheral: \(saved?.name ?? "nil")")
            print("📱 Saved peripheral ID: \(saved?.identifier.uuidString ?? "nil")")
        }
    }
    
    /// DELEGATE METHOD - Wywoływane gdy nie uda się połączyć z urządzeniem
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "Unknown")")
        
        /// Wyczyść połączone urządzenie w Actor (nie ma połączenia)
        Task { [weak self] in
            await self?.state.setConnectedPeripheral(nil)
        }
    }
    
    /// DELEGATE METHOD - Wywoływane gdy urządzenie się rozłączy
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from: \(peripheral.name ?? "Unknown")")
        if let error = error {
            print("🔌 Disconnect reason: \(error.localizedDescription)")
        }
        
        Task { [weak self] in
            print("📱 Clearing peripheral from BluetoothState...")
            await self?.state.setConnectedPeripheral(nil)
            
            let saved = await self?.state.connectedPeripheral
            print("📱 Verified cleared peripheral: \(saved?.name ?? "still there!" )")
        }
    }
    
}
