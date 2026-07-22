//
//  DefaultCentralManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth
import OSLog
import SharedModels

public final class DefaultCentralManager: NSObject, CentralManager, @unchecked Sendable {
   
   /// Oryginalny CBCentralManager z CoreBluetooth
   private let cbCentralManager: CBCentralManager
    
   /// Aktory które zarządzają stanem - thread-safe
   let statusActor = BluetoothStatusActor()
   let scanActor = BluetoothScanActor()

   /// Multicast held-HR-strap connection events (nil = połączony, wartość = powód dropu).
   let connectionActor = BluetoothConnectionActor()
   
   override init() {
       /// Tworzymy CBCentralManager bez delegate (na razie nil)
       cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
       super.init()
       
       /// WAŻNE: Ustawiamy siebie jako delegate DOPIERO po inicjalizacji
       cbCentralManager.delegate = self
       
       Logger.bluetooth.debug("[DefaultCentralManager] init")
   }
    
    deinit {
        Logger.bluetooth.debug("[DefaultCentralManager] deinit")
    }
   
   // MARK: - CentralManager Protocol Implementation
   
   /// Zwraca NOWY strumień znalezionych urządzeń za każdym wywołaniem
   public func discoveredDevices() async -> AsyncStream<CBPeripheral> {
       Logger.bluetooth.debug("[DefaultCentralManager] newScanStream")
       return await scanActor.newScanStream()
   }
   
   /// Zwraca NOWY strumień zmian statusu Bluetooth
   public func statusUpdates() async -> AsyncStream<BluetoothStatus> {
       return await statusActor.newStatusStream()
   }

   /// Zwraca NOWY strumień powodów rozłączenia przytrzymanego czujnika HR
   public func hrSensorConnectionEvents() async -> AsyncStream<SensorDisconnectReason?> {
       return await connectionActor.newStream()
   }

   /// Emituje powód rozłączenia (lub `nil` = połączony) do subskrybentów. Wołane z
   /// delegata CoreBluetooth (sync, CB queue) — stąd hop `Task` do aktora.
   func emitHRSensorConnectionReason(_ reason: SensorDisconnectReason?) {
       Task { await connectionActor.broadcast(reason) }
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
       Logger.bluetooth.info("[DefaultCentralManager] initializeBluetooth()")
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
       
       Logger.bluetooth.info("[DefaultCentralManager] scanning started")
   }
   
   /// Zatrzymuje skanowanie urządzeń
   public func stopScanning() async {
       cbCentralManager.stopScan()
       await scanActor.finishScanning()
       
       Logger.bluetooth.info("[DefaultCentralManager] scanning stopped")
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

    // MARK: - Workout sensor hold (IOS-00100-D, experiment)

    /// Peripherals deliberately kept connected for the duration of a workout.
    /// Guarded by `heldLock` — mutated from async API calls, read on the
    /// CoreBluetooth delegate queue (`isHeldPeripheral`). Instance state is fine:
    /// the manager lives as a singleton behind `liveValue`.
    private let heldLock = NSLock()
    private var heldPeripherals: [UUID: CBPeripheral] = [:]

    public func holdHRSensorConnections() async -> Int {
        let sensors = cbCentralManager.retrieveConnectedPeripherals(withServices: [
            Gatt.Service.heartRate
        ])
        // `withLock` — bare lock()/unlock() are unavailable in async contexts
        // (Swift 6: suspending while holding a lock risks deadlock); the scoped
        // variant keeps the critical section synchronous.
        heldLock.withLock {
            for sensor in sensors {
                heldPeripherals[sensor.identifier] = sensor
            }
        }
        for sensor in sensors {
            /// Parallel app-side connection — CoreBluetooth multiplexes one physical
            /// link between clients, so this does not steal the sensor from HealthKit.
            cbCentralManager.connect(sensor)
            Logger.bluetooth.info("[Connection] HOLD: \(sensor.name ?? "Unknown") — parallel connect issued")
        }
        return sensors.count
    }

    public func releaseHRSensorConnections() async {
        let held: [CBPeripheral] = heldLock.withLock {
            let values = Array(heldPeripherals.values)
            heldPeripherals.removeAll()
            return values
        }
        for sensor in held {
            cbCentralManager.cancelPeripheralConnection(sensor)
            Logger.bluetooth.info("[Connection] RELEASE: \(sensor.name ?? "Unknown")")
        }
    }

    /// Delegate-side check — a held peripheral that disconnects mid-workout gets
    /// an immediate pending re-connect (`didDisconnectPeripheral`).
    func isHeldPeripheral(_ id: UUID) -> Bool {
        heldLock.withLock {
            heldPeripherals[id] != nil
        }
    }

    // MARK: - BLE diagnostics (IOS-00100-④: why did the strap drop / was data flowing)

    /// Timestamps of the last disconnect per peripheral — lets `didConnect` log
    /// "reconnected after Xs" so the session file shows real reconnect latency.
    private var droppedAt: [UUID: Date] = [:]

    /// Timestamp of the last HR NOTIFY received per peripheral (BLE layer, our
    /// own subscription). Lets the log distinguish "strap went silent" from
    /// "strap kept sending but HealthKit did not deliver".
    private var lastNotifyAt: [UUID: Date] = [:]

    /// Records a disconnect moment (called from the delegate). Also clears the
    /// notify tracker so the first measurement after ANY reconnect logs
    /// "notify STARTED" — without this, a short (<60 s) outage would reconnect
    /// silently, and the singleton would carry the tracker into the NEXT
    /// workout ("silent for 7200s" instead of a fresh start).
    func noteDrop(_ id: UUID) {
        heldLock.withLock {
            droppedAt[id] = Date()
            lastNotifyAt[id] = nil
        }
    }

    /// Returns seconds since the recorded drop (and clears it) — `nil` for a
    /// first-time connect.
    func takeDropInterval(_ id: UUID) -> TimeInterval? {
        heldLock.withLock {
            guard let dropped = droppedAt.removeValue(forKey: id) else { return nil }
            return Date().timeIntervalSince(dropped)
        }
    }

    /// Registers an HR notification and decides whether it deserves a file-log
    /// line: first one ever / first after a silence gap. Returns the silence
    /// duration to log, `nil` when the stream is just flowing normally.
    func noteHRNotify(_ id: UUID) -> (isFirst: Bool, silenceGap: TimeInterval?)? {
        let notifyLogGap: TimeInterval = 60
        return heldLock.withLock {
            let now = Date()
            defer { lastNotifyAt[id] = now }
            guard let previous = lastNotifyAt[id] else { return (isFirst: true, silenceGap: nil) }
            let gap = now.timeIntervalSince(previous)
            guard gap > notifyLogGap else { return nil }
            return (isFirst: false, silenceGap: gap)
        }
    }
   
   // MARK: - Private Helpers
   
   /// Mapuje CBManagerState na BluetoothStatus i aktualizuje Actor
   public func updateStatusFromCBState(_ cbState: CBManagerState) async {
       let newStatus = mapCBStateToBluetoothStatus(cbState)
       await statusActor.updateStatus(newStatus)
       
       Logger.bluetooth.info("[DefaultCentralManager] status: \(String(describing: cbState)) → \(String(describing: newStatus))")
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
