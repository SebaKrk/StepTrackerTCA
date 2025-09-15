//
//  BluetoothScanActor.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth

/// Actor odpowiedzialny za skanowanie urządzeń Bluetooth
@preconcurrency
actor BluetoothScanActor {
    
    init() {
        print("🟢 BluetoothScanActor init")
    }
    
    deinit {
        print("🪦 -> ❌ BluetoothScanActor deinit - cleanup scan streams")
        scanContinuation?.finish()
    }
    
    // MARK: - Scan Properties
    
    /// Czy aktualnie skanujemy urządzenia
    var isScanning = false
    
    /// Lista znalezionych urządzeń (opcjonalnie)
    var discoveredDevices: [CBPeripheral] = []
    
    // MARK: - Stream Properties
    
    /// Kontynuacja dla streamu skanowania
    private var scanContinuation: AsyncStream<CBPeripheral>.Continuation?
    
    // MARK: - Scan Methods
    
    /// Thread-safe update skanowania
    func updateScanning(_ value: Bool) {
        isScanning = value
        if !value {
            // Jeśli przestajemy skanować, wyczyść listę urządzeń
            discoveredDevices.removeAll()
        }
    }
    
    func startScanning() {
        print("🚀 BluetoothScanActor: Starting scanning")
        isScanning = true
        discoveredDevices.removeAll()
    }
    
    func stopScanning() {
        print("🛑 BluetoothScanActor: Stopping scanning")
        isScanning = false
    }
    
    // MARK: - Scan Stream Methods
    
    func newScanStream() -> AsyncStream<CBPeripheral> {
        print("🔄 BluetoothScanActor: Tworzę nowy scan stream")
        
        // Zakończ poprzedni stream jeśli istnieje
        if let oldContinuation = scanContinuation {
            print("💀 BluetoothScanActor: Kończę poprzedni scan stream")
            oldContinuation.finish()
        }
        
        // Utwórz nowy stream z nową kontynuacją
        let newStream = AsyncStream<CBPeripheral> { newContinuation in
            print("✨ BluetoothScanActor: Otrzymuję nową scan kontynuację")
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
            print("⚠️ BluetoothScanActor: Próba yield ale nie skanujemy lub brak kontynuacji")
            return
        }
        
        // Dodaj do listy znalezionych urządzeń (jeśli nie ma już)
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
        
        print("📤 BluetoothScanActor: Yielding peripheral: \(peripheral.name ?? "Unknown")")
        continuation.yield(peripheral)
    }
    
    func finishScanning() {
        print("🛑 BluetoothScanActor: Finishing scan stream")
        
        scanContinuation?.finish()
        scanContinuation = nil
        isScanning = false
    }
    
    // MARK: - Private Methods
    
    private func handleScanTermination(_ termination: AsyncStream<CBPeripheral>.Continuation.Termination) {
        switch termination {
        case .finished:
            print("✅ BluetoothScanActor: Scan stream finished normally")
        case .cancelled:
            print("❌ BluetoothScanActor: Scan stream was cancelled")
        @unknown default:
            print("❓ BluetoothScanActor: Scan stream terminated with unknown reason")
        }
        
        scanContinuation = nil
        isScanning = false
    }
    
    // MARK: - Debug Methods
    
    var hasActiveScanContinuation: Bool {
        scanContinuation != nil
    }
    
    func printScanStatus() {
        print("📊 BluetoothScanActor Scan Status:")
        print("   - Is Scanning: \(isScanning)")
        print("   - Has Scan Continuation: \(hasActiveScanContinuation)")
        print("   - Discovered Devices: \(discoveredDevices.count)")
    }
}
