//
//  DefaultCentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

public final class DefaultCentralManager: NSObject, CentralManager, @unchecked Sendable {
   
   /// Oryginalny CBCentralManager z CoreBluetooth - to jest główny obiekt który komunikuje się z systemem Bluetooth
   private let cbCentralManager: CBCentralManager
   
   /// Strumień przez który płyną znalezione urządzenia do TCA
   /// ZMIANA: var zamiast let - żeby móc recreate
   private var deviceStream: AsyncStream<CBPeripheral>
   
   /// Kontynuacja do wysyłania urządzeń przez strumień
   /// ZMIANA: var zamiast let - żeby móc recreate
   var deviceContinuation: AsyncStream<CBPeripheral>.Continuation
   
   /// Stream przez który płyną zmiany statusu Bluetooth do TCA
   private let statusStream: AsyncStream<BluetoothStatus>
   
   /// Kontynuacja do wysyłania statusów przez strumień
   let statusContinuation: AsyncStream<BluetoothStatus>.Continuation
   
   /// Stream dla zdarzeń połączenia
   private let connectionStream: AsyncStream<ConnectionEvent>
   
   /// Kontynuacja do wysyłania eventów połączenia przez strumień
   let connectionContinuation: AsyncStream<ConnectionEvent>.Continuation
    
   /// Actor który zarządza stanem - thread-safe
   let state = BluetoothState()
   
   override init() {
       /// Tworzymy parę AsyncStream dla urządzeń - strumień i kontynuację
       let (deviceStream, deviceContinuation) = AsyncStream.makeStream(of: CBPeripheral.self)
       self.deviceStream = deviceStream
       self.deviceContinuation = deviceContinuation
       
       /// Tworzymy parę AsyncStream dla statusów
       let (statusStream, statusContinuation) = AsyncStream.makeStream(of: BluetoothStatus.self)
       self.statusStream = statusStream
       self.statusContinuation = statusContinuation
       
       /// Tworzymy parę AsyncStream dla zdarzeń połączenia
       let (connectionStream, connectionContinuation) = AsyncStream.makeStream(of: ConnectionEvent.self)
       self.connectionStream = connectionStream
       self.connectionContinuation = connectionContinuation
       
       /// Tworzymy CBCentralManager bez delegate (na razie nil)
       cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
       super.init()
       
       /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
       cbCentralManager.delegate = self
       
       /// Wysyłamy początkowy status
       statusContinuation.yield(.unknown)
       
       print("📱 Created DefaultCentralManager with initial device stream")
   }
   
   // MARK: - CentralManager Protocol Implementation
   
   /// Zwraca strumień znalezionych urządzeń - TCA będzie tego nasłuchiwać
   public var discoveredDevices: AsyncStream<CBPeripheral> {
       deviceStream
   }
   
   /// Zwraca strumień zmian statusu Bluetooth
   public var bluetoothStatusUpdates: AsyncStream<BluetoothStatus> { statusStream }
   
   /// Zwraca strumień zdarzeń połączenia
   public var connectionEvents: AsyncStream<ConnectionEvent> { connectionStream }
   
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
       
       /// NOWE: Utwórz fresh stream przed każdym skanowaniem
       recreateDeviceStream()
       
       cbCentralManager.scanForPeripherals(withServices: [Gatt.Service.heartRate])
       await state.updateScanning(true)
       print("🔍 Started scanning for devices with fresh stream")
   }
   
   /// Zatrzymuje skanowanie urządzeń
   public func stopScanning() async {
       cbCentralManager.stopScan()
       await state.updateScanning(false)
       
       /// NOWE: Zakończ obecny stream
       deviceContinuation.finish()
       
       print("⏹️ Stopped scanning and finished device stream")
   }
   
   /// Łączy się z wybranym urządzeniem
   public func connect(to peripheral: CBPeripheral) async throws {
       guard await state.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       /// Wyślij event że próbujemy się połączyć
       connectionContinuation.yield(.connecting(peripheral))
       
       /// Zatrzymaj skanowanie przed połączeniem
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
   
   /// NOWA FUNKCJA: Tworzy nowy device stream i continuation
   private func recreateDeviceStream() {
       let (newStream, newContinuation) = AsyncStream.makeStream(of: CBPeripheral.self)
       self.deviceStream = newStream
       self.deviceContinuation = newContinuation
       
       print("🆕 Created fresh device stream and continuation")
   }
   
   /// Mapuje CBManagerState na BluetoothStatus i aktualizuje Actor + Stream
   public func updateStatusFromCBState(_ cbState: CBManagerState) async {
       let newStatus = mapCBStateToBluetoothStatus(cbState)
       
       await state.updateStatus(newStatus)
       statusContinuation.yield(newStatus)
       
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
