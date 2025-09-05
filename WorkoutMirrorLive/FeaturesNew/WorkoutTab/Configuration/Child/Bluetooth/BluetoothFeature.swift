//
//  ActivityPickerFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth
import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

@Reducer
struct BluetoothFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    @Dependency(\.bluetoothClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .bluetoothStatusChanged(status):
                // Aktualizuj stan Feature
                state.bluetoothStatus = status
                
                // Reaguj na konkretne zmiany
                switch status {
                case .ready:
                    // Bluetooth gotowy - można automatycznie startować scan
                    if !state.isScanning {
                        return .run { send in
                            try await client.startScanning()
                            await send(.scanningStarted)
                        }
                    }
                    
                case .disabled:
                    // Bluetooth wyłączony - zatrzymaj skanowanie jeśli trwa
                    if state.isScanning {
                        state.isScanning = false
                        state.discoveredPeripherals.removeAll()
                        return .run { send in
                            await client.stopScanning()
                        }
                    }
                    
                case .unauthorized:
                    // Brak uprawnień - zatrzymaj skanowanie i wyczyść listę
                    state.isScanning = false
                    state.discoveredPeripherals.removeAll()
                    
                case .unknown, .unsupported, .disconnected:
                    // Stany przejściowe lub błędy
                    break
                }
                
                return .none
                
                
            case .scanningStarted:
                state.isScanning = true
                /// Rozpoczynamy nasłuchiwanie znalezionych urządzeń
                print("scanningStarted")
                return .run { send in
                    for await device in await client.discoveredDevices() {
                        await send(.deviceDiscovered(device))
                    }
                }
                
            case .scanningStopped:
                state.isScanning = false
                print("⏹️ Scanning stopped")
                return .none
                
//            case let .deviceDiscovered(peripheral):
//                /// Dodajemy urządzenie do listy jeśli jeszcze go nie ma
//                if !state.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
//                    state.discoveredPeripherals.append(peripheral)
//                    print("📡 BluetoothFeature: Discovered NEW device: \(peripheral.name ?? "Unknown")")
//                }
//                return .none
                
            case let .deviceDiscovered(peripheral):
                // Zawsze aktualizuj listę - pokaż wszystkie urządzenia
                if let existingIndex = state.discoveredPeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                    // Zaktualizuj istniejące urządzenie (może mieć nowy stan połączenia)
                    state.discoveredPeripherals[existingIndex] = peripheral
                    print("🔄 Updated device: \(peripheral.name ?? "Unknown"), state: \(peripheral.state.rawValue)")
                } else {
                    // Dodaj nowe urządzenie
                    state.discoveredPeripherals.append(peripheral)
                    print("📡 New device: \(peripheral.name ?? "Unknown"), state: \(peripheral.state.rawValue)")
                }
                return .none
                
            case .connectionEventReceived(let event):
                switch event {
                case .connecting(let peripheral):
                    state.connectionStatus = "Connecting to \(peripheral.name ?? "Unknown")..."
                    print(state.connectionStatus)
                    
                case .connected(let peripheral):
                    state.connectedDevice = peripheral
                    state.connectionStatus = "Connected to \(peripheral.name ?? "Unknown")"
                    print(state.connectionStatus)
                    
                case .disconnected(let peripheral, let error):
                    state.connectedDevice = nil
                    let errorMsg = error != nil ? " (\(error!))" : ""
                    state.connectionStatus = "Disconnected from \(peripheral.name ?? "Unknown")\(errorMsg)"
                    print(state.connectionStatus)
                    
                case .failedToConnect(let peripheral, let error):
                    state.connectedDevice = nil
                    let errorMsg = error ?? "Unknown error"
                    state.connectionStatus = "Failed to connect to \(peripheral.name ?? "Unknown"): \(errorMsg)"
                    print(state.connectionStatus)
                    
                }
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                // Startuj nasłuchiwanie statusu Bluetooth
                return .run { send in
                    // 1. Inicjalizuj Bluetooth manager
                    //await client.initializeBluetooth()
                    let currentStatus = await client.currentStatus()
                    await send(.bluetoothStatusChanged(currentStatus))
                    
                    // 2. NASŁUCHUJ ZMIAN przez AsyncStream - nieskończona pętla!
                    for await status in await client.bluetoothStatusUpdates() {
                        await send(.bluetoothStatusChanged(status))
                    }
                }
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await client.stopScanning()
                    await send(.scanningStopped)
                    await self.dismiss()
                }
                
            case .view(.scanningButtonTapped):
                if state.isScanning {
                    // Zatrzymaj skanowanie
                    return .run { send in
                        await client.stopScanning()
                        await send(.scanningStopped)
                    }
                } else {
                    // Rozpocznij skanowanie (tylko jeśli Bluetooth gotowy)
                    guard state.bluetoothStatus == .ready else {
                        return .none
                    }
                    return .run { send in
                        try await client.startScanning()
                        await send(.scanningStarted)
                    }
                }
                
            case .view(.deviceTapped(let peripheral)):
                state.connectionStatus = "Connecting to \(peripheral.name ?? "Unknown")..."
                return .run { send in
                    try await client.connect(peripheral)
                    
                    // Nasłuchuj zdarzeń połączenia
                    for await event in await client.connectionEvents() {
                        await send(.connectionEventReceived(event))
                    }
                }
            }
        }
    }
}

/// Implementation of `BluetoothFeature` action
extension BluetoothFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case bluetoothStatusChanged(BluetoothStatus)
        
        ///
        case scanningStarted
        
        ///
        case scanningStopped
        
        ///
        case deviceDiscovered(CBPeripheral)
        
        case connectionEventReceived(ConnectionEvent)
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case closeButtonTapped
            
            ///
            case scanningButtonTapped
            
            ///
            case deviceTapped(CBPeripheral)
        }
    }
}

/// Implementation of `BluetoothFeature` state
extension BluetoothFeature {
    
    @ObservableState
    struct State {
        
        ///
        var bluetoothStatus: BluetoothStatus = .unknown
        
        ///
        var isScanning: Bool = false
        
        ///
        var discoveredPeripherals: [CBPeripheral] = []
        
        ///
        var connectedDevice: CBPeripheral? = nil
        
        ///
        var connectionStatus: String = ""
    }
    
}

