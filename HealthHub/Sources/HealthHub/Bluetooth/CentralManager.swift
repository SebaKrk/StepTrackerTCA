//
//  CentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth

/// Protokół dla zarządzania Bluetooth Central Manager
/// Sendable = bezpieczny dla współbieżności (Swift 6)
public protocol CentralManager: Sendable {
    
    // MARK: - Properties (async bo Actor)
    
    /// Czy Bluetooth jest włączony i gotowy
    /// async = bo może wymagać dostępu do Actor state
    var isPoweredOn: Bool { get async }
    
    /// Czy aktualnie skanuje urządzenia
    var isScanning: Bool { get async }
    
    // MARK: - Async Methods (nowoczesne API)
    
    /// Rozpocznij skanowanie urządzeń BLE
    /// async throws = może trwać długo i może nie powieść się
    func startScanning() async throws
    
    /// Zatrzymaj skanowanie urządzeń
    /// async = może trwać chwilę ale zawsze się uda
    func stopScanning() async
    
    // MARK: - Event Streams (komunikacja z TCA)
    
    /// Strumień znalezionych urządzeń podczas skanowania
    /// AsyncStream = jak nieskończona tablica którą można nasłuchiwać
    /// TCA będzie nasłuchiwać tego strumienia i dostawać każde nowe urządzenie
    var discoveredDevices: AsyncStream<CBPeripheral> { get }
}


//import CoreBluetooth
//
//public protocol CentralManager: Sendable {
//    
//    // MARK: - Properties
//    
//    /// Aktualnie połączone urządzenie
//    var connectedPeripheral: CBPeripheral? { get set }
//    
//    /// Lista znalezionych urządzeń podczas skanowania
//    var discoveredPeripherals: [CBPeripheral] { get set }
//    
//    /// Czy Bluetooth jest włączony i gotowy
//    var isPoweredOn: Bool { get }
//    
//    /// Czy aktualnie skanuje urządzenia
//    var isScanning: Bool { get }
//    
//    // MARK: - Methods
//    
//    /// Rozpocznij skanowanie urządzeń BLE
//    func startScanning()
//    
//    /// Zatrzymaj skanowanie urządzeń
//    func stopScanning()
//    
//    /// Połącz się z wybranym urządzeniem
//    func connect(to peripheral: CBPeripheral)
//    
//    /// Rozłącz aktualne połączenie
//    func disconnect()
//}
