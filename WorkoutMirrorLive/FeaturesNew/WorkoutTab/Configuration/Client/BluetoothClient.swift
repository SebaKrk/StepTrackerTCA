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
    
    /// NOWA FUNKCJA - Triggeruje inicjalizację Bluetooth (fire and forget)
    /// Manager wyśle statusy przez bluetoothStatusUpdates stream
    public var initializeBluetooth: @Sendable () async -> Void
    
    /// Rozpoczyna skanowanie urządzeń BLE
    /// Zwraca Effect który może wysyłać Actions do TCA Feature
    public var startScanning: @Sendable () async throws -> Void
    
    /// Zatrzymuje skanowanie urządzeń BLE
    /// Zwraca Effect który może wysyłać Actions do TCA Feature
    public var stopScanning: @Sendable () async -> Void
    
    /// Nasłuchuje znalezionych urządzeń jako AsyncStream
    /// TCA Feature będzie tego używać żeby dostawać nowe urządzenia w real-time
    public var discoveredDevices: @Sendable () -> AsyncStream<CBPeripheral>
    
    /// NOWY STREAM - Nasłuchuje zmian statusu Bluetooth jako AsyncStream
    /// TCA Feature będzie tego używać żeby pokazać progress view i wiedzieć kiedy można skanować
    public var bluetoothStatusUpdates: @Sendable () -> AsyncStream<BluetoothStatus>
    
    /// Sprawdza czy Bluetooth jest włączony
    public var isPoweredOn: @Sendable () async -> Bool
    
    /// Sprawdza czy aktualnie skanuje
    public var isScanning: @Sendable () async -> Bool
    
    /// NOWA PROPERTY - Sprawdza aktualny status Bluetooth
    public var currentStatus: @Sendable () async -> BluetoothStatus
    
    /// Połącz się z wybranym urządzeniem
    public var connect: @Sendable (CBPeripheral) async throws -> Void
    
    /// Rozłącz aktualne połączenie
    public var disconnect: @Sendable () async -> Void
    
    /// Stream zdarzeń połączenia
    public var connectionEvents: @Sendable () -> AsyncStream<ConnectionEvent>
    
    /// Aktualnie połączone urządzenie
    public var connectedPeripheral: @Sendable () async -> CBPeripheral?
}

// MARK: - Dependency Registration

/// Klucz do rejestracji BluetoothClient w TCA Dependency System
public enum BluetoothClientKey: DependencyKey {
    
    /// Live implementation - rzeczywisty BluetoothClient który używa prawdziwego CentralManager
    public static let liveValue: BluetoothClient = {
        
        /// Pobieramy CentralManager z TCA dependencies
        /// To będzie nasz DefaultCentralManager
        @Dependency(\.centralManager) var centralManager
        
        print("📱 BluetoothClient: Creating with CentralManager")
        
        return BluetoothClient(
            /// NOWA FUNKCJA - Inicjalizuje Bluetooth manager
            initializeBluetooth: {
                print("📱 BluetoothClient: Initializing Bluetooth...")
                await centralManager.initializeBluetooth()
            },
            
            /// Funkcja startScanning - wywołuje centralManager.startScanning()
            startScanning: {
                print("📱 BluetoothClient: Starting scan...")
                try await centralManager.startScanning()
            },
            
            /// Funkcja stopScanning - wywołuje centralManager.stopScanning()
            stopScanning: {
                print("📱 BluetoothClient: Stopping scan...")
                await centralManager.stopScanning()
            },
            
            /// Funkcja discoveredDevices - zwraca strumień z centralManager
            discoveredDevices: {
                print("📱 BluetoothClient: Returning discovered devices stream")
                return centralManager.discoveredDevices
            },
            
            /// NOWY STREAM - Funkcja bluetoothStatusUpdates - zwraca strumień statusów
            bluetoothStatusUpdates: {
                print("📱 BluetoothClient: Returning bluetooth status updates stream")
                return centralManager.bluetoothStatusUpdates
            },
            
            /// Funkcja isPoweredOn - zwraca stan Bluetooth z centralManager
            isPoweredOn: {
                return await centralManager.isPoweredOn
            },
            
            /// Funkcja isScanning - zwraca stan skanowania z centralManager
            isScanning: {
                return await centralManager.isScanning
            },
            
            /// NOWA PROPERTY - Funkcja currentStatus - zwraca aktualny status
            currentStatus: {
                return await centralManager.currentStatus
            },
            connect: { peripheral in
                print("📱 BluetoothClient: Connecting to \(peripheral.name ?? "Unknown")...")
                try await centralManager.connect(to: peripheral)
            },
            
            /// Funkcja disconnect - rozłącza urządzenie
            disconnect: {
                print("📱 BluetoothClient: Disconnecting...")
                await centralManager.disconnect()
            },
            
            /// Stream zdarzeń połączenia
            connectionEvents: {
                print("📱 BluetoothClient: Returning connection events stream")
                return centralManager.connectionEvents
            },
            /// Aktualnie połączone urządzenie
            connectedPeripheral: {
                return await centralManager.connectedPeripheral
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
