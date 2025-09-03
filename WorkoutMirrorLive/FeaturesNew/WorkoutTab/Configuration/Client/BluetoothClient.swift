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
    
    /// Rozpoczyna skanowanie urządzeń BLE
    /// Zwraca Effect który może wysyłać Actions do TCA Feature
    public var startScanning: @Sendable () async throws -> Void
    
    /// Zatrzymuje skanowanie urządzeń BLE
    /// Zwraca Effect który może wysyłać Actions do TCA Feature
    public var stopScanning: @Sendable () async -> Void
    
    /// Nasłuchuje znalezionych urządzeń jako AsyncStream
    /// TCA Feature będzie tego używać żeby dostawać nowe urządzenia w real-time
    public var discoveredDevices: @Sendable () -> AsyncStream<CBPeripheral>
    
    /// Sprawdza czy Bluetooth jest włączony
    public var isPoweredOn: @Sendable () async -> Bool
    
    /// Sprawdza czy aktualnie skanuje
    public var isScanning: @Sendable () async -> Bool
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
            
            /// Funkcja isPoweredOn - zwraca stan Bluetooth z centralManager
            isPoweredOn: {
                return await centralManager.isPoweredOn
            },
            
            /// Funkcja isScanning - zwraca stan skanowania z centralManager
            isScanning: {
                return await centralManager.isScanning
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
