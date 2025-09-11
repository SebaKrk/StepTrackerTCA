//
//  BluetoothState.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 03/09/2025.
//

import CoreBluetooth

/// Actor który zarządza stanem Bluetooth + obsługuje skanowanie stream
@preconcurrency
actor BluetoothState {
    
    // MARK: - Bluetooth State Properties
    
    /// Czy aktualnie skanujemy urządzenia
    var isScanning = false
    
    /// Czy Bluetooth jest włączony i gotowy do użycia
    var isPoweredOn = false
    
    /// Aktualny status systemu Bluetooth (mapowany z CBManagerState)
    var status: BluetoothStatus = .unknown
    
    var connectedPeripheral: CBPeripheral? = nil
    
    // MARK: - Scan Continuation Properties
    
    /// Kontynuacja dla streamu skanowania
    private var scanContinuation: AsyncStream<CBPeripheral>.Continuation?
    
    // MARK: - Bluetooth State Methods
    
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
        isPoweredOn = (newStatus == .ready)
    }
        
    func setConnectedPeripheral(_ peripheral: CBPeripheral?) {
        connectedPeripheral = peripheral
    }
    
    // MARK: - Scan Stream Methods
    
    func newScanStream() -> AsyncStream<CBPeripheral> {
        print("🔄 BluetoothState: Tworzę nowy scan stream")
        
        // Zakończ poprzedni stream jeśli istnieje
        if let oldContinuation = scanContinuation {
            print("💀 BluetoothState: Kończę poprzedni scan stream")
            oldContinuation.finish()
        }
        
        // Utwórz nowy stream z nową kontynuacją
        let newStream = AsyncStream<CBPeripheral> { newContinuation in
            print("✨ BluetoothState: Otrzymuję nową scan kontynuację")
            self.scanContinuation = newContinuation
            
            // Cleanup przy zakończeniu streamu
            newContinuation.onTermination = { @Sendable [weak self] termination in
                Task {
                    await self?.handleScanTermination(termination)
                }
            }
        }
        
        return newStream
    }
    
    func yieldDevice(_ peripheral: CBPeripheral) {
        guard isScanning, let continuation = scanContinuation else {
            print("⚠️ BluetoothState: Próba yield ale nie skanujemy lub brak kontynuacji")
            return
        }
        
        print("📤 BluetoothState: Yielding peripheral: \(peripheral.name ?? "Unknown")")
        continuation.yield(peripheral)
    }
    
    func finishScanning() {
        print("🛑 BluetoothState: Finishing scan stream")
        
        scanContinuation?.finish()
        scanContinuation = nil
        isScanning = false
    }
    
    func startScanning() {
        print("🚀 BluetoothState: Starting scanning")
        isScanning = true
    }
    
    // MARK: - Private Methods
    
    private func handleScanTermination(_ termination: AsyncStream<CBPeripheral>.Continuation.Termination) {
        switch termination {
        case .finished:
            print("✅ BluetoothState: Scan stream finished normally")
        case .cancelled:
            print("❌ BluetoothState: Scan stream was cancelled")
        @unknown default:
            print("❓ BluetoothState: Scan stream terminated with unknown reason")
        }
        
        scanContinuation = nil
        isScanning = false
    }
    
    // MARK: - Debug Methods
    
    var hasActiveScanContinuation: Bool {
        scanContinuation != nil
    }
    
    func printScanStatus() {
        print("📊 BluetoothState Scan Status:")
        print("   - Is Scanning: \(isScanning)")
        print("   - Has Scan Continuation: \(hasActiveScanContinuation)")
    }
}
