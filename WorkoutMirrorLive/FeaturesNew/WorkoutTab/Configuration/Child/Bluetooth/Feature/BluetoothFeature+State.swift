//
//  BluetoothFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth
import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

/// Implementation of `BluetoothFeature` state
extension BluetoothFeature {
    @ObservableState
    struct State {
        
        // MARK: - Core Properties
        
        /// Aktualny status systemu Bluetooth (ready/disabled/unauthorized/unknown)
        /// Determinuje który widok jest pokazywany użytkownikowi
        var bluetoothStatus: BluetoothStatus
        
        /// Czy aplikacja aktualnie skanuje urządzenia BLE
        /// Kontroluje wyświetlanie progress indicatora i dostępność przycisku skanowania
        var isScanning: Bool = false
        
        /// Lista wszystkich urządzeń znalezionych podczas skanowania
        /// Zawiera urządzenia z bieżącej sesji skanowania oraz systemowe urządzenia
        var discoveredPeripherals: [CBPeripheral] = []
        
        /// Urządzenia połączone na poziomie systemu iOS
        /// Pobierane z getConnectedPeripherals() - urządzenia połączone przez system lub inne aplikacje
        var systemConnectedDevices: [CBPeripheral] = []
        
        /// Urządzenie aktywnie wybrane przez użytkownika w aplikacji
        /// nil = brak wybranego urządzenia, CBPeripheral = wybrane urządzenie
        var selectedDevice: CBPeripheral? = nil
        
        // MARK: - Computed Properties
        
        /// Wszystkie urządzenia uznane za "połączone" przez aplikację
        /// Łączy systemConnectedDevices + selectedDevice (bez duplikatów)
        /// Używane do wyświetlania sekcji "Connected Devices"
        var connectedDevices: [CBPeripheral] {
            var devices = systemConnectedDevices
            
            if let selected = selectedDevice,
               !devices.contains(where: { $0.identifier == selected.identifier }) {
                devices.append(selected)
            }
            
            return devices
        }
        
        /// Urządzenia dostępne do połączenia
        /// Filtruje discoveredPeripherals: pokazuje tylko rozłączone urządzenia,
        /// które nie są już w connectedDevices
        var availableDevices: [CBPeripheral] {
            discoveredPeripherals.filter { device in
                device.state == .disconnected &&
                !connectedDevices.contains(where: { $0.identifier == device.identifier })
            }
        }
    }
}
