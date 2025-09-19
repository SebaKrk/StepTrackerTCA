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
    
   /// Aktory które zarządzają stanem - thread-safe
   let statusActor = BluetoothStatusActor()
   let scanActor = BluetoothScanActor()
   
   override init() {
       /// Tworzymy CBCentralManager bez delegate (na razie nil)
       cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
       super.init()
       
       /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
       cbCentralManager.delegate = self
       
       print("📱 🟢 Created DefaultCentralManager with separate actors")
   }
    
    deinit {
        print("🪦 -> ❌ DefaultCentralManager deinit")
    }
   
   // MARK: - CentralManager Protocol Implementation
   
   /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
   public func discoveredDevices() async -> AsyncStream<CBPeripheral> {
       print("scanActor.newScanStream")
       return await scanActor.newScanStream()
   }
   
   /// Zwraca NOWY strumień zmian statusu Bluetooth
   public func statusUpdates() async -> AsyncStream<BluetoothStatus> {
       return await statusActor.newStatusStream()
   }
   
   /// Czy Bluetooth jest włączony - async bo Actor wymaga await
   public var isPoweredOn: Bool {
       get async { await statusActor.isPoweredOn }
   }
   
   /// Czy aktualnie skanuje - async bo Actor wymaga await
   public var isScanning: Bool {
       get async { await scanActor.isScanning }
   }
   
   /// Aktualny status systemu Bluetooth
   public var currentStatus: BluetoothStatus {
       get async { await statusActor.status }
   }
   
//   /// Aktualnie połączone urządzenie (jedno)
//   public var connectedPeripheral: CBPeripheral? {
//       get async { await statusActor.connectedPeripheral }
//   }
   
   /// Triggeruje inicjalizację managera
   public func initializeBluetooth() async {
       print("📱 DefaultCentralManager: initializeBluetooth() called")
       let currentCBState = cbCentralManager.state
       await updateStatusFromCBState(currentCBState)
   }
   
   /// Rozpoczyna skanowanie urządzeń BLE z serwisem Heart Rate
   public func startScanning() async throws {
       guard await statusActor.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       await scanActor.startScanning()
       cbCentralManager.scanForPeripherals(withServices: [
           Gatt.Service.heartRate
       ])
       
       print("🔍 Started scanning for devices")
   }
   
   /// Zatrzymuje skanowanie urządzeń
   public func stopScanning() async {
       cbCentralManager.stopScan()
       await scanActor.finishScanning()
       
       print("ℹ️ Stopped scanning")
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
       guard await statusActor.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       /// Zatrzymaj skanowanie przed połączeniem
       await stopScanning()
       
       /// Rozpocznij połączenie - wynik będzie w delegate callback
       cbCentralManager.connect(peripheral)
   }
   
   /// Rozłącza aktualnie połączone urządzenie
    public func disconnect(_ peripheral: CBPeripheral) async {
       cbCentralManager.cancelPeripheralConnection(peripheral)
   }
    
    public func checkConnectedDevicesFirst() async -> [CBPeripheral] {
        cbCentralManager.retrieveConnectedPeripherals(withServices: [
            Gatt.Service.heartRate
        ])
    }
   
   // MARK: - Private Helpers
   
   /// Mapuje CBManagerState na BluetoothStatus i aktualizuje Actor
   public func updateStatusFromCBState(_ cbState: CBManagerState) async {
       let newStatus = mapCBStateToBluetoothStatus(cbState)
       await statusActor.updateStatus(newStatus)
       
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
