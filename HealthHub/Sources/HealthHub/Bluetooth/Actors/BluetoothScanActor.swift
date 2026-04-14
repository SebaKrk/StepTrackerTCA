//
//  BluetoothScanActor.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth
import OSLog
import SharedModels

/// Actor odpowiedzialny za skanowanie urządzeń Bluetooth
@preconcurrency
actor BluetoothScanActor {
    
    init() {
        Logger.bluetooth.debug("[BluetoothScanActor] init")
    }

    deinit {
        Logger.bluetooth.debug("[BluetoothScanActor] deinit")
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
        Logger.bluetooth.info("[BluetoothScanActor] startScanning")
        isScanning = true
        discoveredDevices.removeAll()
    }

    func stopScanning() {
        Logger.bluetooth.info("[BluetoothScanActor] stopScanning")
        isScanning = false
    }
    
    // MARK: - Scan Stream Methods
    
    func newScanStream() -> AsyncStream<CBPeripheral> {
        Logger.bluetooth.debug("[BluetoothScanActor] new scan stream")

        // Zakończ poprzedni stream jeśli istnieje
        if let oldContinuation = scanContinuation {
            Logger.bluetooth.debug("[BluetoothScanActor] finishing previous scan stream")
            oldContinuation.finish()
        }

        // Utwórz nowy stream z nową kontynuacją
        let newStream = AsyncStream<CBPeripheral> { newContinuation in
            Logger.bluetooth.debug("[BluetoothScanActor] new continuation set")
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
            Logger.bluetooth.notice("[BluetoothScanActor] yieldDevice — not scanning or no continuation")
            return
        }

        // Dodaj do listy znalezionych urządzeń (jeśli nie ma już)
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }

        Logger.bluetooth.debug("[BluetoothScanActor] yielding: \(peripheral.name ?? "Unknown")")
        continuation.yield(peripheral)
    }

    func finishScanning() {
        Logger.bluetooth.debug("[BluetoothScanActor] finishing scan stream")
        
        scanContinuation?.finish()
        scanContinuation = nil
        isScanning = false
    }
    
    // MARK: - Private Methods
    
    private func handleScanTermination(_ termination: AsyncStream<CBPeripheral>.Continuation.Termination) {
        switch termination {
        case .finished:
            Logger.bluetooth.debug("[BluetoothScanActor] scan stream finished")
        case .cancelled:
            Logger.bluetooth.debug("[BluetoothScanActor] scan stream cancelled")
        @unknown default:
            Logger.bluetooth.notice("[BluetoothScanActor] scan stream unknown termination")
        }
        
        scanContinuation = nil
        isScanning = false
    }
    
    // MARK: - Debug Methods
    
    var hasActiveScanContinuation: Bool {
        scanContinuation != nil
    }
    
    func printScanStatus() {
        Logger.bluetooth.debug("[BluetoothScanActor] isScanning=\(self.isScanning) continuation=\(self.hasActiveScanContinuation) discovered=\(self.discoveredDevices.count)")
    }
}
