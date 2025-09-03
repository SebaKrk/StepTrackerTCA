//
//  CentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth

public protocol CentralManager: Sendable {
    
    // MARK: - Properties
    
    /// Aktualnie połączone urządzenie
    var connectedPeripheral: CBPeripheral? { get set }
    
    /// Lista znalezionych urządzeń podczas skanowania
    var discoveredPeripherals: [CBPeripheral] { get set }
    
    /// Czy Bluetooth jest włączony i gotowy
    var isPoweredOn: Bool { get }
    
    /// Czy aktualnie skanuje urządzenia
    var isScanning: Bool { get }
    
    // MARK: - Methods
    
    /// Rozpocznij skanowanie urządzeń BLE
    func startScanning()
    
    /// Zatrzymaj skanowanie urządzeń
    func stopScanning()
    
    /// Połącz się z wybranym urządzeniem
    func connect(to peripheral: CBPeripheral)
    
    /// Rozłącz aktualne połączenie
    func disconnect()
}
