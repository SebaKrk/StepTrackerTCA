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
   
   /// Aktualny status systemu Bluetooth
   var currentStatus: BluetoothStatus { get async }
   
   /// Aktualnie połączone urządzenie (jedno)
//   var connectedPeripheral: CBPeripheral? { get async }
   
   // MARK: - Async Methods (nowoczesne API)
   
   /// Rozpocznij skanowanie urządzeń BLE
   /// async throws = może trwać długo i może nie powieść się
   func startScanning() async throws
   
   /// Zatrzymaj skanowanie urządzeń
   /// async = może trwać chwilę ale zawsze się uda
   func stopScanning() async
   
   /// Triggeruje inicjalizację managera (fire and forget)
   /// Manager sam wyśle aktualizacje stanu przez bluetoothStatusUpdates
   func initializeBluetooth() async
   
   /// Połącz się z wybranym urządzeniem
   func connect(to peripheral: CBPeripheral) async throws
   
   /// Rozłącz aktualne połączenie
    func disconnect(_ peripheral: CBPeripheral) async
    
    /// Zwraca urządzenia aktualnie połączone z systemem iOS które mają określone serwisy
    func getConnectedPeripherals() async -> [CBPeripheral]
    
    /// Sprawdza czy system iOS ma już połączone urządzenia HR
    func checkConnectedDevicesFirst() async -> [CBPeripheral]

    /// EXPERIMENT (IOS-00100-D): przytrzymaj równoległe, app-side połączenie do
    /// podłączonych czujników HR na czas treningu. Po zerwaniu delegat wystawia
    /// pending `connect()` (bez timeoutu) — czujnik wraca do zasięgu → system
    /// łączy natychmiast, co MOŻE skracać re-asocjację HealthKit.
    /// Zwraca liczbę przytrzymanych czujników.
    func holdHRSensorConnections() async -> Int

    /// Zwalnia połączenia przytrzymane przez `holdHRSensorConnections()`
    /// (koniec treningu) — bez tego pending connect wisiałby wiecznie.
    func releaseHRSensorConnections() async

   // MARK: - Event Streams (komunikacja z TCA)
   
   /// Strumień znalezionych urządzeń podczas skanowania
   /// AsyncStream = jak nieskończona tablica którą można nasłuchiwać
   /// TCA będzie nasłuchiwać tego strumienia i dostawać każde nowe urządzenie
   /// UWAGA: Za każdym razem gdy wywołasz startScanning() - dostaniesz NOWY stream!
   func discoveredDevices() async -> AsyncStream<CBPeripheral>
   
   /// Strumień zmian statusu Bluetooth
   /// Wyśle aktualny status od razu po subskrypcji, a potem każdą zmianę
   func statusUpdates() async -> AsyncStream<BluetoothStatus>
}
