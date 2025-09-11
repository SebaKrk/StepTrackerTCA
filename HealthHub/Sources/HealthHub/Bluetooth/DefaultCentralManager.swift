//
//  DefaultCentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

public final class DefaultCentralManager: NSObject, CentralManager, @unchecked Sendable {
   
   /// Oryginalny CBCentralManager z CoreBluetooth
   private let cbCentralManager: CBCentralManager
    
   /// Actor który zarządza stanem - thread-safe
   let state = BluetoothState()
   
   override init() {
       /// Tworzymy CBCentralManager bez delegate (na razie nil)
       cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
       super.init()
       
       /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
       cbCentralManager.delegate = self
       
       print("📱 Created DefaultCentralManager")
   }
   
   // MARK: - CentralManager Protocol Implementation
   
   /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
   public func discoveredDevices() async -> AsyncStream<CBPeripheral> {
       return await state.newScanStream()
   }
   
   /// Czy Bluetooth jest włączony - async bo Actor wymaga await
   public var isPoweredOn: Bool {
       get async { await state.isPoweredOn }
   }
   
   /// Czy aktualnie skanuje - async bo Actor wymaga await
   public var isScanning: Bool {
       get async { await state.isScanning }
   }
   
   /// Aktualny status systemu Bluetooth
   public var currentStatus: BluetoothStatus {
       get async { await state.status }
   }
   
   /// Aktualnie połączone urządzenie (jedno)
   public var connectedPeripheral: CBPeripheral? {
       get async { await state.connectedPeripheral }
   }
   
   /// Triggeruje inicjalizację managera
   public func initializeBluetooth() async {
       print("📱 DefaultCentralManager: initializeBluetooth() called")
       let currentCBState = cbCentralManager.state
       await updateStatusFromCBState(currentCBState)
   }
   
   /// Rozpoczyna skanowanie urządzeń BLE z serwisem Heart Rate
   public func startScanning() async throws {
       guard await state.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       await state.startScanning()
       cbCentralManager.scanForPeripherals(withServices: [
           Gatt.Service.heartRate,
           Gatt.Service.weightScale
       ])
       
       print("🔍 Started scanning for devices")
   }
   
   /// Zatrzymuje skanowanie urządzeń
   public func stopScanning() async {
       cbCentralManager.stopScan()
       await state.finishScanning()
       
       print("⏹️ Stopped scanning")
   }
   
    /// Zwraca urządzenia aktualnie połączone z systemem iOS które mają określone serwisy
    public func getConnectedPeripherals() async -> [CBPeripheral] {
        return cbCentralManager.retrieveConnectedPeripherals(withServices: [
            Gatt.Service.heartRate,
            Gatt.Service.weightScale
        ])
    }
    
   /// Łączy się z wybranym urządzeniem
   public func connect(to peripheral: CBPeripheral) async throws {
       guard await state.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       /// Zatrzymaj skanowanie przed połączeniem
       ///
       await stopScanning()
       
       /// Rozpocznij połączenie - wynik będzie w delegate callback
       cbCentralManager.connect(peripheral)
   }
   
   /// Rozłącza aktualnie połączone urządzenie
   public func disconnect() async {
       guard let peripheral = await state.connectedPeripheral else { return }
       cbCentralManager.cancelPeripheralConnection(peripheral)
   }
   
   // MARK: - Private Helpers
   
   /// Mapuje CBManagerState na BluetoothStatus i aktualizuje Actor
   public func updateStatusFromCBState(_ cbState: CBManagerState) async {
       let newStatus = mapCBStateToBluetoothStatus(cbState)
       await state.updateStatus(newStatus)
       
       print("🔵 Status updated: \(cbState) → \(newStatus)")
   }
   
   /// Pomocnicza funkcja mapująca CBManagerState na BluetoothStatus
   private func mapCBStateToBluetoothStatus(_ cbState: CBManagerState) -> BluetoothStatus {
       switch cbState {
       case .poweredOn:
           return .ready
       case .poweredOff:
           return .disabled
       case .unauthorized:
           return .unauthorized
       case .unsupported:
           return .unsupported
       case .unknown, .resetting:
           return .unknown
       @unknown default:
           return .unknown
       }
   }
}
