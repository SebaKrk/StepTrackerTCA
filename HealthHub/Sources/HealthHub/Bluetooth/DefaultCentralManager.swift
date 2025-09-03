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
    
    /// Actor który zarządza stanem - thread-safe
    let state = BluetoothState()
    
    override init() {
        /// Tworzymy parę AsyncStream - strumień i kontynuację
        let (stream, continuation) = AsyncStream.makeStream(of: CBPeripheral.self)
        self.deviceStream = stream
        self.deviceContinuation = continuation
        
        /// Tworzymy CBCentralManager bez delegate (na razie nil)
        cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
        /// Dzięki temu nie dostaniemy callback przed zakończeniem init()
        cbCentralManager.delegate = self
    }
    
    // MARK: - CentralManager Protocol Implementation
    
    /// Zwraca strumień znalezionych urządzeń - TCA będzie tego nasłuchiwać
    /// Każde urządzenie które znajdzie delegate automatycznie "wpływa" tym strumieniem do TCA
    public var discoveredDevices: AsyncStream<CBPeripheral> { deviceStream }
    
    /// Czy Bluetooth jest włączony - async bo Actor wymaga await
    public var isPoweredOn: Bool {
        get async { await state.isPoweredOn }
    }
    
    /// Czy aktualnie skanuje - async bo Actor wymaga await
    public var isScanning: Bool {
        get async { await state.isScanning }
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
