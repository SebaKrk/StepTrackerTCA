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
import OSLog
import SharedModels

/// Klient Bluetooth dla TCA - to jest most między TCA Feature a CentralManager
/// Zawiera funkcje które TCA może wywoływać jako Effects
public struct BluetoothClient: Sendable {
    
    /// Triggeruje inicjalizację Bluetooth managera
    public var initializeBluetooth: @Sendable () async -> Void
    
    /// Pobiera aktualny status Bluetooth na żądanie (bez streamowania)
    public var getCurrentStatus: @Sendable () async -> BluetoothStatus
    
    /// Zwraca NOWY strumień zmian statusu Bluetooth za każdym wywołaniem
    public var statusUpdates: @Sendable () async -> AsyncStream<BluetoothStatus>
    
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
    public var disconnect: @Sendable (CBPeripheral) async -> Void
    
    /// Aktualnie połączone urządzenie
//    public var connectedPeripheral: @Sendable () async -> CBPeripheral?
    
    /// Zwraca urządzenia aktualnie połączone z systemem iOS
     public var getConnectedPeripherals: @Sendable () async -> [CBPeripheral]
    
    /// Sprawdza czy system iOS ma już połączone urządzenia HR/Weight Scale
    public var checkConnectedDevicesFirst: @Sendable () async -> [CBPeripheral]
}

// MARK: - Dependency Registration

/// Klucz do rejestracji BluetoothClient w TCA Dependency System
public enum BluetoothClientKey: DependencyKey {
    
    /// Live implementation - rzeczywisty BluetoothClient który używa prawdziwego CentralManager
    public static let liveValue: BluetoothClient = {
        
        /// Pobieramy CentralManager z TCA dependencies
        @Dependency(\.centralManager) var centralManager
        
        Logger.bluetooth.debug("[BluetoothClient] liveValue created")

        return BluetoothClient(
            /// Inicjalizuje Bluetooth manager
            initializeBluetooth: {
                Logger.bluetooth.info("[BluetoothClient] initializeBluetooth")
                await centralManager.initializeBluetooth()
            },

            /// Pobiera aktualny status na żądanie
            getCurrentStatus: {
                return await centralManager.currentStatus
            },

            /// Zwraca NOWY strumień zmian statusu za każdym wywołaniem
            statusUpdates: {
                Logger.bluetooth.debug("[BluetoothClient] statusUpdates — new stream")
                return await centralManager.statusUpdates()
            },

            /// Rozpoczyna skanowanie
            startScanning: {
                Logger.bluetooth.info("[BluetoothClient] startScanning")
                try await centralManager.startScanning()
            },

            /// Zatrzymuje skanowanie
            stopScanning: {
                Logger.bluetooth.info("[BluetoothClient] stopScanning")
                await centralManager.stopScanning()
            },

            /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
            discoveredDevices: {
                Logger.bluetooth.debug("[BluetoothClient] discoveredDevices — new stream")
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
                Logger.bluetooth.info("[BluetoothClient] connect → \(peripheral.name ?? "Unknown")")
                try await centralManager.connect(to: peripheral)
            },

            /// Rozłącza urządzenie
            disconnect: { peripheral in
                Logger.bluetooth.info("[BluetoothClient] disconnect → \(peripheral.name ?? "Unknown")")
                await centralManager.disconnect(peripheral)
            },
            
//            /// Zwraca aktualnie połączone urządzenie
//            connectedPeripheral: {
//                return await centralManager.connectedPeripheral
//            },
            
            /// Zwraca urządzenia aktualnie połączone z systemem iOS
            getConnectedPeripherals: {
                return await centralManager.getConnectedPeripherals()
            },
            /// Sprawdza połączone urządzenia
            checkConnectedDevicesFirst: {
                return await centralManager.checkConnectedDevicesFirst()
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
