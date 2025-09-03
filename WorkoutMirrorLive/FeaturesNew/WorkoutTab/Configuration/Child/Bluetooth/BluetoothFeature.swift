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
                
            case .scanningStarted:
                /// Rozpoczynamy nasłuchiwanie znalezionych urządzeń
                print("scanningStarted")
                return .run { send in
                    for await device in client.discoveredDevices() {
                        await send(.deviceDiscovered(device))
                    }
                }
                
            case let .deviceDiscovered(peripheral):
                /// Dodajemy urządzenie do listy jeśli jeszcze go nie ma
                if !state.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                       state.discoveredPeripherals.append(peripheral)
                       print("📡 BluetoothFeature: Discovered NEW device: \(peripheral.name ?? "Unknown")")
                }
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    do {
                        try await client.startScanning()
                        await send(.scanningStarted)
                    } catch {
                        print("❌ BluetoothFeature: Failed to start scanning: \(error)")
                    }
                }
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.stopScanningButtonTapped):
                return .run { send in
                    await client.stopScanning()
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
        case scanningStarted
        
        ///
        case deviceDiscovered(CBPeripheral)
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case closeButtonTapped
            
            ///
            case stopScanningButtonTapped
        }
    }
}

/// Implementation of `BluetoothFeature` state
extension BluetoothFeature {
    
    @ObservableState
    struct State {
        
        ///
        var discoveredPeripherals: [CBPeripheral] = []
    }
    
}

