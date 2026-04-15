//
//  BluetoothStatusActor.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth
import OSLog
import SharedModels

/// Actor odpowiedzialny za zarządzanie statusem Bluetooth
@preconcurrency
actor BluetoothStatusActor {
    
    init() {
        Logger.bluetooth.debug("[BluetoothStatusActor] init")
    }
    
    deinit {
        Logger.bluetooth.debug("[BluetoothStatusActor] deinit")
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
            Logger.bluetooth.info("[BluetoothStatusActor] status: \(String(describing: oldStatus)) → \(String(describing: newStatus))")
            yieldStatus(newStatus)
        }
    }
        
//    func setConnectedPeripheral(_ peripheral: CBPeripheral?) {
//        connectedPeripheral = peripheral
//    }
    
    // MARK: - Status Stream Methods
    
    func newStatusStream() -> AsyncStream<BluetoothStatus> {
        Logger.bluetooth.debug("[BluetoothStatusActor] new status stream")
        
        // Zakończ poprzedni stream jeśli istnieje
        if let oldContinuation = statusContinuation {
            Logger.bluetooth.debug("[BluetoothStatusActor] finishing previous status stream")
            oldContinuation.finish()
        }
        
        // Utwórz nowy stream z nową kontynuacją
        let newStream = AsyncStream<BluetoothStatus> { newContinuation in
            Logger.bluetooth.debug("[BluetoothStatusActor] new continuation set")
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
            Logger.bluetooth.notice("[BluetoothStatusActor] yieldStatus — no continuation")
            return
        }
        
        Logger.bluetooth.debug("[BluetoothStatusActor] yielding: \(String(describing: status))")
        continuation.yield(status)
    }
    
    func finishStatusStream() {
        Logger.bluetooth.debug("[BluetoothStatusActor] finishing status stream")
        
        statusContinuation?.finish()
        statusContinuation = nil
    }
    
    // MARK: - Private Methods
    
    private func handleStatusTermination(_ termination: AsyncStream<BluetoothStatus>.Continuation.Termination) {
        switch termination {
        case .finished:
            Logger.bluetooth.debug("[BluetoothStatusActor] status stream finished")
        case .cancelled:
            Logger.bluetooth.debug("[BluetoothStatusActor] status stream cancelled")
        @unknown default:
            Logger.bluetooth.notice("[BluetoothStatusActor] status stream unknown termination")
        }
        
        statusContinuation = nil
    }
    
    // MARK: - Debug Methods
    
    var hasActiveStatusContinuation: Bool {
        statusContinuation != nil
    }
    
    func printStatusStreamStatus() {
        Logger.bluetooth.debug("[BluetoothStatusActor] status=\(String(describing: self.status)) continuation=\(self.hasActiveStatusContinuation) poweredOn=\(self.isPoweredOn)")
    }
}
