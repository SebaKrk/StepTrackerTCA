//
//  BluetoothClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import ComposableArchitecture
import CoreBluetooth
import Foundation
import HealthHub

/// Klient Bluetooth dla TCA - to jest most między TCA Feature a CentralManager
/// Zawiera funkcje które TCA może wywoływać jako Effects
public struct BluetoothClient: Sendable {
    
    /// Triggeruje inicjalizację Bluetooth managera
    public var initializeBluetooth: @Sendable () async -> Void
    
    /// Pobiera aktualny status Bluetooth na żądanie (bez streamowania)
    public var getCurrentStatus: @Sendable () async -> BluetoothStatus
    
    /// Rozpoczyna skanowanie urządzeń BLE
    public var startScanning: @Sendable () async throws -> Void
    
    /// Zatrzymuje skanowanie urządzeń BLE
    public var stopScanning: @Sendable () async -> Void
    
    /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
    public var discoveredDevices: @Sendable () async -> AsyncStream<CBPeripheral>
    
    /// Sprawdza czy Bluetooth jest włączony
    public var isPoweredOn: @Sendable () async -> Bool
    
    /// Sprawdza czy aktualnie skanuje
    public var isScanning: @Sendable () async -> Bool
    
    /// Łączy się z wybranym urządzeniem
    public var connect: @Sendable (CBPeripheral) async throws -> Void
    
    /// Rozłącza aktualne połączenie
    public var disconnect: @Sendable () async -> Void
    
    /// Aktualnie połączone urządzenie
    public var connectedPeripheral: @Sendable () async -> CBPeripheral?
    
    /// Zwraca urządzenia aktualnie połączone z systemem iOS
     public var getConnectedPeripherals: @Sendable () async -> [CBPeripheral]
}

// MARK: - Dependency Registration

/// Klucz do rejestracji BluetoothClient w TCA Dependency System
public enum BluetoothClientKey: DependencyKey {
    
    /// Live implementation - rzeczywisty BluetoothClient który używa prawdziwego CentralManager
    public static let liveValue: BluetoothClient = {
        
        /// Pobieramy CentralManager z TCA dependencies
        @Dependency(\.centralManager) var centralManager
        
        print("📱 BluetoothClient: Creating with CentralManager")
        
        return BluetoothClient(
            /// Inicjalizuje Bluetooth manager
            initializeBluetooth: {
                print("📱 BluetoothClient: Initializing Bluetooth...")
                await centralManager.initializeBluetooth()
            },
            
            /// Pobiera aktualny status na żądanie
            getCurrentStatus: {
                return await centralManager.currentStatus
            },
            
            /// Rozpoczyna skanowanie
            startScanning: {
                print("📱 BluetoothClient: Starting scan...")
                try await centralManager.startScanning()
            },
            
            /// Zatrzymuje skanowanie
            stopScanning: {
                print("📱 BluetoothClient: Stopping scan...")
                await centralManager.stopScanning()
            },
            
            /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
            discoveredDevices: {
                print("📱 BluetoothClient: Creating new discovered devices stream")
                return await centralManager.discoveredDevices()
            },
            
            /// Sprawdza czy Bluetooth włączony
            isPoweredOn: {
                return await centralManager.isPoweredOn
            },
            
            /// Sprawdza czy skanuje
            isScanning: {
                return await centralManager.isScanning
            },
            
            /// Łączy z urządzeniem
            connect: { peripheral in
                print("📱 BluetoothClient: Connecting to \(peripheral.name ?? "Unknown")...")
                try await centralManager.connect(to: peripheral)
            },
            
            /// Rozłącza urządzenie
            disconnect: {
                print("📱 BluetoothClient: Disconnecting...")
                await centralManager.disconnect()
            },
            
            /// Zwraca aktualnie połączone urządzenie
            connectedPeripheral: {
                return await centralManager.connectedPeripheral
            },
            
            /// Zwraca urządzenia aktualnie połączone z systemem iOS
            getConnectedPeripherals: {
                return await centralManager.getConnectedPeripherals()
            }
        )
    }()
}

/// Rozszerzenie TCA DependencyValues żeby można było używać bluetoothClient
public extension DependencyValues {
    var bluetoothClient: BluetoothClient {
        get { self[BluetoothClientKey.self] }
        set { self[BluetoothClientKey.self] = newValue }
    }
}

// MARK: - Usunięte tymczasowo (będą dodawane osobno później):
// public var bluetoothStatusUpdates: @Sendable () -> AsyncStream<BluetoothStatus>
// public var connectionEvents: @Sendable () -> AsyncStream<ConnectionEvent>


//import ComposableArchitecture
//import CoreBluetooth
//import Foundation
//import HealthHub
//
///// Klient Bluetooth dla TCA - to jest most między TCA Feature a CentralManager
///// Zawiera funkcje które TCA może wywoływać jako Effects
//public struct BluetoothClient: Sendable {
//    
//    /// Triggeruje inicjalizację Bluetooth managera
//    public var initializeBluetooth: @Sendable () async -> Void
//    
//    /// Pobiera aktualny status Bluetooth na żądanie (bez streamowania)
//    public var getCurrentStatus: @Sendable () async -> BluetoothStatus
//    
//    /// Rozpoczyna skanowanie urządzeń BLE
//    public var startScanning: @Sendable () async throws -> Void
//    
//    /// Zatrzymuje skanowanie urządzeń BLE
//    public var stopScanning: @Sendable () async -> Void
//    
//    /// Nasłuchuje znalezionych urządzeń jako AsyncStream
//    public var discoveredDevices: @Sendable () -> AsyncStream<CBPeripheral>
//    
//    /// Nasłuchuje zmian statusu Bluetooth jako AsyncStream
//    public var bluetoothStatusUpdates: @Sendable () -> AsyncStream<BluetoothStatus>
//    
//    /// Sprawdza czy Bluetooth jest włączony
//    public var isPoweredOn: @Sendable () async -> Bool
//    
//    /// Sprawdza czy aktualnie skanuje
//    public var isScanning: @Sendable () async -> Bool
//    
//    /// Łączy się z wybranym urządzeniem
//    public var connect: @Sendable (CBPeripheral) async throws -> Void
//    
//    /// Rozłącza aktualne połączenie
//    public var disconnect: @Sendable () async -> Void
//    
//    /// Stream zdarzeń połączenia
//    public var connectionEvents: @Sendable () -> AsyncStream<ConnectionEvent>
//    
//    /// Aktualnie połączone urządzenie
//    public var connectedPeripheral: @Sendable () async -> CBPeripheral?
//}
//
//// MARK: - Dependency Registration
//
///// Klucz do rejestracji BluetoothClient w TCA Dependency System
//public enum BluetoothClientKey: DependencyKey {
//    
//    /// Live implementation - rzeczywisty BluetoothClient który używa prawdziwego CentralManager
//    public static let liveValue: BluetoothClient = {
//        
//        /// Pobieramy CentralManager z TCA dependencies
//        @Dependency(\.centralManager) var centralManager
//        
//        print("📱 BluetoothClient: Creating with CentralManager")
//        
//        return BluetoothClient(
//            /// Inicjalizuje Bluetooth manager
//            initializeBluetooth: {
//                print("📱 BluetoothClient: Initializing Bluetooth...")
//                await centralManager.initializeBluetooth()
//            },
//            
//            /// Pobiera aktualny status na żądanie
//            getCurrentStatus: {
//                return await centralManager.currentStatus
//            },
//            
//            /// Rozpoczyna skanowanie
//            startScanning: {
//                print("📱 BluetoothClient: Starting scan...")
//                try await centralManager.startScanning()
//            },
//            
//            /// Zatrzymuje skanowanie
//            stopScanning: {
//                print("📱 BluetoothClient: Stopping scan...")
//                await centralManager.stopScanning()
//            },
//            
//            /// Zwraca strumień znalezionych urządzeń
//            discoveredDevices: {
//                print("📱 BluetoothClient: Returning discovered devices stream")
//                return centralManager.discoveredDevices
//            },
//            
//            /// Zwraca strumień statusów Bluetooth
//            bluetoothStatusUpdates: {
//                print("📱 BluetoothClient: Returning bluetooth status updates stream")
//                return centralManager.bluetoothStatusUpdates
//            },
//            
//            /// Sprawdza czy Bluetooth włączony
//            isPoweredOn: {
//                return await centralManager.isPoweredOn
//            },
//            
//            /// Sprawdza czy skanuje
//            isScanning: {
//                return await centralManager.isScanning
//            },
//            
//            /// Łączy z urządzeniem
//            connect: { peripheral in
//                print("📱 BluetoothClient: Connecting to \(peripheral.name ?? "Unknown")...")
//                try await centralManager.connect(to: peripheral)
//            },
//            
//            /// Rozłącza urządzenie
//            disconnect: {
//                print("📱 BluetoothClient: Disconnecting...")
//                await centralManager.disconnect()
//            },
//            
//            /// Zwraca strumień zdarzeń połączenia
//            connectionEvents: {
//                print("📱 BluetoothClient: Returning connection events stream")
//                return centralManager.connectionEvents
//            },
//            
//            /// Zwraca aktualnie połączone urządzenie
//            connectedPeripheral: {
//                return await centralManager.connectedPeripheral
//            }
//        )
//    }()
//}
//
///// Rozszerzenie TCA DependencyValues żeby można było używać bluetoothClient
//public extension DependencyValues {
//    var bluetoothClient: BluetoothClient {
//        get { self[BluetoothClientKey.self] }
//        set { self[BluetoothClientKey.self] = newValue }
//    }
//}
