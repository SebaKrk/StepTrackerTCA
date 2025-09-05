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
    /// To jest "rurka" którą TCA może nasłuchiwać
    private let deviceStream: AsyncStream<CBPeripheral>
    
    /// Kontynuacja do wysyłania urządzeń przez strumień
    /// To jest "zawór" przez który wrzucamy urządzenia do rurki
    let deviceContinuation: AsyncStream<CBPeripheral>.Continuation
    
    /// NOWY STREAM - Strumień przez który płyną zmiany statusu Bluetooth do TCA
    private let statusStream: AsyncStream<BluetoothStatus>
    
    /// NOWA KONTYNUACJA - Zawór do wysyłania statusów przez strumień
    let statusContinuation: AsyncStream<BluetoothStatus>.Continuation
    
    /// Stream dla zdarzeń połączenia
     private let connectionStream: AsyncStream<ConnectionEvent>
    
    ///
     let connectionContinuation: AsyncStream<ConnectionEvent>.Continuation
     
    
    /// Actor który zarządza stanem - thread-safe
    let state = BluetoothState()
    
    override init() {
        /// Tworzymy parę AsyncStream dla urządzeń - strumień i kontynuację
        let (deviceStream, deviceContinuation) = AsyncStream.makeStream(of: CBPeripheral.self)
        self.deviceStream = deviceStream
        self.deviceContinuation = deviceContinuation
        
        /// NOWY STREAM - Tworzymy parę AsyncStream dla statusów
        let (statusStream, statusContinuation) = AsyncStream.makeStream(of: BluetoothStatus.self)
        self.statusStream = statusStream
        self.statusContinuation = statusContinuation
        
        let (connectionStream, connectionContinuation) = AsyncStream.makeStream(of: ConnectionEvent.self)
        self.connectionStream = connectionStream
        self.connectionContinuation = connectionContinuation
        
        
        /// Tworzymy CBCentralManager bez delegate (na razie nil)
        cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        
        /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
        /// Dzięki temu nie dostaniemy callback przed zakończeniem init()
        cbCentralManager.delegate = self
        
        /// Wysyłamy początkowy status
        statusContinuation.yield(.unknown)
    }
    
    // MARK: - CentralManager Protocol Implementation
    
    /// Zwraca strumień znalezionych urządzeń - TCA będzie tego nasłuchiwać
    /// Każde urządzenie które znajdzie delegate automatycznie "wpływa" tym strumieniem do TCA
    public var discoveredDevices: AsyncStream<CBPeripheral> { deviceStream }
    
    /// NOWY STREAM - Zwraca strumień zmian statusu Bluetooth
    public var bluetoothStatusUpdates: AsyncStream<BluetoothStatus> { statusStream }
    
    public var connectionEvents: AsyncStream<ConnectionEvent> { connectionStream }
    
    /// Czy Bluetooth jest włączony - async bo Actor wymaga await
    public var isPoweredOn: Bool {
        get async { await state.isPoweredOn }
    }
    
    /// Czy aktualnie skanuje - async bo Actor wymaga await
    public var isScanning: Bool {
        get async { await state.isScanning }
    }
    
    /// NOWA PROPERTY - Aktualny status systemu Bluetooth
    public var currentStatus: BluetoothStatus {
        get async { await state.status }
    }
    
    public var connectedPeripheral: CBPeripheral? {
        get async { await state.connectedPeripheral }
    }
    
    /// NOWA FUNKCJA - Triggeruje inicjalizację managera (już jest zrobiona w init())
    /// Ta funkcja głównie po to żeby Feature mógł "powiedzieć" że potrzebuje Bluetooth
    public func initializeBluetooth() async {
        print("📱 DefaultCentralManager: initializeBluetooth() called")
        // Manager już jest zainicjalizowany w init()
        // Ale możemy sprawdzić aktualny stan i wymusić update
        let currentCBState = cbCentralManager.state
        await updateStatusFromCBState(currentCBState)
    }
    
    /// Rozpoczyna skanowanie urządzeń BLE
    /// async throws = funkcja może trwać długo i może rzucić błąd
    public func startScanning() async throws {
        /// Sprawdzamy czy Bluetooth jest włączony (async wywołanie)
        guard await state.isPoweredOn else {
            throw BluetoothError.notPoweredOn
        }
        
        /// Mówimy systemowemu CBCentralManager żeby zaczął skanować
        /// Szukamy tylko urządzeń z serwisem Heart Rate (180D)
        cbCentralManager.scanForPeripherals(withServices: [Gatt.Service.heartRate])
        
        /// Thread-safe update stanu przez Actor
        await state.updateScanning(true)
        print("🔍 Started scanning for devices")
    }
    
    /// Zatrzymuje skanowanie urządzeń
    /// async = może trwać chwilę ale nie rzuca błędów
    public func stopScanning() async {
        /// Mówimy systemowemu CBCentralManager żeby przestał skanować
        cbCentralManager.stopScan()
        
        /// Thread-safe update stanu przez Actor
        await state.updateScanning(false)
        print("⏹️ Stopped scanning")
    }
    
    public func connect(to peripheral: CBPeripheral) async throws {
        guard await state.isPoweredOn else {
            throw BluetoothError.notPoweredOn
        }
        
        await state.setConnectedPeripheral(peripheral)
        cbCentralManager.connect(peripheral)
        await stopScanning()
        
        connectionContinuation.yield(.connecting(peripheral))
    }
    
    public func disconnect() async {
        guard let peripheral = await state.connectedPeripheral else { return }
        
        cbCentralManager.cancelPeripheralConnection(peripheral)
        await state.setConnectedPeripheral(nil)
    }
    
    // MARK: - Private Helpers
    
    /// Mapuje CBManagerState na BluetoothStatus i aktualizuje Actor + Stream
    public func updateStatusFromCBState(_ cbState: CBManagerState) async {
        let newStatus = mapCBStateToBluetoothStatus(cbState)
        
        /// Aktualizuj Actor (thread-safe)
        await state.updateStatus(newStatus)
        
        /// Wyślij nowy status przez stream do TCA
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

//
//import CoreBluetooth
//
//final class DefaultCentralManager: NSObject, CentralManager {
//    
//    let cbCentralManager: CBCentralManager
//    
//    var connectedPeripheral: CBPeripheral?
//    var discoveredPeripherals: [CBPeripheral] = []
//    
//    var isPoweredOn = false
//    var isScanning = false
//    
//    override init() {
//        self.cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
//        super.init()
//        self.cbCentralManager.delegate = self
//    }
//    
//    public func startScanning() {
//        guard isPoweredOn else {
//            return
//        }
//        cbCentralManager.scanForPeripherals(withServices: [Gatt.Service.heartRate])
//        isScanning = true
//    }
//    
//    public func stopScanning() {
//        cbCentralManager.stopScan()
//        isScanning = false
//        discoveredPeripherals = []
//    }
//    
//    func connect(to peripheral: CBPeripheral) {
//        connectedPeripheral = peripheral
//        cbCentralManager.connect(peripheral)
//        stopScanning()
//    }
//    
//    func disconnect() {
//        guard let peripheral = connectedPeripheral else {
//            return
//        }
//        cbCentralManager.cancelPeripheralConnection(peripheral)
//        connectedPeripheral = nil
//    }
//    
//}
