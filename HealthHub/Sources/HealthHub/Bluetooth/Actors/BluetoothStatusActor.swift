//
//  BluetoothStatusActor.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth

/// Actor odpowiedzialny za zarządzanie statusem Bluetooth
@preconcurrency
actor BluetoothStatusActor {
    
    init() {
        print("🟢 BluetoothStatusActor init")
    }
    
    deinit {
        print("🪦 -> ❌ BluetoothStatusActor deinit - cleanup status stream")
        statusContinuation?.finish()
    }
    
    // MARK: - Status Properties
    
    /// Czy Bluetooth jest włączony i gotowy do użycia
    var isPoweredOn = false
    
    /// Aktualny status systemu Bluetooth (mapowany z CBManagerState)
    var status: BluetoothStatus = .unknown
    
//    var connectedPeripheral: CBPeripheral? = nil
    
    // MARK: - Stream Properties
    
    /// Kontynuacja dla streamu statusu Bluetooth
    private var statusContinuation: AsyncStream<BluetoothStatus>.Continuation?
    
    // MARK: - Status Methods
    
    /// Thread-safe update stanu Bluetooth
    func updatePowerState(_ value: Bool) {
        isPoweredOn = value
    }
    
    /// Thread-safe update statusu systemu
    func updateStatus(_ newStatus: BluetoothStatus) {
        let oldStatus = status
        status = newStatus
        isPoweredOn = (newStatus == .ready)
        
        // Jeśli status się zmienił, wyślij przez stream
        if oldStatus != newStatus {
            print("📡 BluetoothStatusActor: Status changed from \(oldStatus) to \(newStatus)")
            yieldStatus(newStatus)
        }
    }
        
//    func setConnectedPeripheral(_ peripheral: CBPeripheral?) {
//        connectedPeripheral = peripheral
//    }
    
    // MARK: - Status Stream Methods
    
    func newStatusStream() -> AsyncStream<BluetoothStatus> {
        print("🔄 BluetoothStatusActor: Tworzę nowy status stream")
        
        // Zakończ poprzedni stream jeśli istnieje
        if let oldContinuation = statusContinuation {
            print("💀 BluetoothStatusActor: Kończę poprzedni status stream")
            oldContinuation.finish()
        }
        
        // Utwórz nowy stream z nową kontynuacją
        let newStream = AsyncStream<BluetoothStatus> { newContinuation in
            print("✨ BluetoothStatusActor: Otrzymuję nową status kontynuację")
            self.statusContinuation = newContinuation
            
            // Wyślij aktualny status od razu
            newContinuation.yield(self.status)
            
            // Cleanup przy zakończeniu streamu
            newContinuation.onTermination = { @Sendable [weak self] termination in
                Task {
                    await self?.handleStatusTermination(termination)
                }
            }
        }
        
        return newStream
    }
    
    private func yieldStatus(_ status: BluetoothStatus) {
        guard let continuation = statusContinuation else {
            print("⚠️ BluetoothStatusActor: Próba yield status ale brak kontynuacji")
            return
        }
        
        print("📤 BluetoothStatusActor: Yielding status: \(status)")
        continuation.yield(status)
    }
    
    func finishStatusStream() {
        print("🛑 BluetoothStatusActor: Finishing status stream")
        
        statusContinuation?.finish()
        statusContinuation = nil
    }
    
    // MARK: - Private Methods
    
    private func handleStatusTermination(_ termination: AsyncStream<BluetoothStatus>.Continuation.Termination) {
        switch termination {
        case .finished:
            print("✅ BluetoothStatusActor: Status stream finished normally")
        case .cancelled:
            print("❌ BluetoothStatusActor: Status stream was cancelled")
        @unknown default:
            print("❓ BluetoothStatusActor: Status stream terminated with unknown reason")
        }
        
        statusContinuation = nil
    }
    
    // MARK: - Debug Methods
    
    var hasActiveStatusContinuation: Bool {
        statusContinuation != nil
    }
    
    func printStatusStreamStatus() {
        print("📊 BluetoothStatusActor Status Stream:")
        print("   - Current Status: \(status)")
        print("   - Has Status Continuation: \(hasActiveStatusContinuation)")
        print("   - Is Powered On: \(isPoweredOn)")
    }
}
