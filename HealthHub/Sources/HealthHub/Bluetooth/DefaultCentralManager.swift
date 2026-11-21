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

/// Central for heart-rate straps: scans, connects and reads heart rate over GATT.
///
/// Background mode: `bluetooth-central` — strap readings keep arriving with the screen off.
public final class DefaultCentralManager: NSObject, CentralManager, @unchecked Sendable {
   
   /// The underlying CoreBluetooth central.
   private let cbCentralManager: CBCentralManager
    
   /// Actors that own the state — thread-safe.
   let statusActor = BluetoothStatusActor()
   let scanActor = BluetoothScanActor()

   /// Multicast held-HR-strap connection events (nil = connected, a value = why it dropped).
   let connectionActor = BluetoothConnectionActor()

   /// Multicast presence of a connected HR sensor (`true` = at least one connected).
   /// Feeds the pre-workout device picker so its status refreshes live.
   let presenceActor = HRSensorPresenceActor()

   /// Multicast strap GATT readings — the HR-fallback source for `iPhoneWorkoutSession`.
   let strapReadingActor = StrapHRReadingActor()
   
   override init() {
       /// Created without a delegate for now.
       cbCentralManager = CBCentralManager(delegate: nil, queue: nil)
       super.init()
       
       /// The delegate can be set only after `super.init()`.
       cbCentralManager.delegate = self
       
       Logger.bluetooth.debug("[DefaultCentralManager] init")
   }
    
    deinit {
        Logger.bluetooth.debug("[DefaultCentralManager] deinit")
    }
   
   // MARK: - CentralManager Protocol Implementation
   
   /// Returns a NEW stream of discovered devices on every call.
   public func discoveredDevices() async -> AsyncStream<CBPeripheral> {
       Logger.bluetooth.debug("[DefaultCentralManager] newScanStream")
       return await scanActor.newScanStream()
   }
   
   /// Returns a NEW stream of Bluetooth status changes.
   public func statusUpdates() async -> AsyncStream<BluetoothStatus> {
       return await statusActor.newStatusStream()
   }

   /// Returns a NEW stream of disconnect reasons for the held HR sensor.
   public func hrSensorConnectionEvents() async -> AsyncStream<SensorDisconnectReason?> {
       return await connectionActor.newStream()
   }

   /// Broadcasts the disconnect reason (or `nil` = connected) to subscribers. Called from the
   /// CoreBluetooth delegate (sync, CB queue) — hence the `Task` hop to the actor.
   func emitHRSensorConnectionReason(_ reason: SensorDisconnectReason?) {
       Task { await connectionActor.broadcast(reason) }
   }

   /// Returns a NEW stream of HR-sensor presence (`true` = a HR sensor is
   /// connected). Yields the CURRENT presence immediately on subscribe (so an
   /// already-connected strap is reflected without waiting for an event), then
   /// on every connect / disconnect. Multicast.
   public func connectedHRSensorPresence() async -> AsyncStream<Bool> {
       return await presenceActor.newStream(initial: currentHRSensorPresence())
   }

   /// Whether at least one HR sensor is currently connected to the system.
   private func currentHRSensorPresence() -> Bool {
       !cbCentralManager.retrieveConnectedPeripherals(
           withServices: [Gatt.Service.heartRate]
       ).isEmpty
   }

   /// Returns a NEW stream of strap GATT readings. Multicast.
   public func strapHRReadings() async -> AsyncStream<StrapHRReading> {
       return await strapReadingActor.newStream()
   }

   /// Broadcasts a strap GATT reading. Called from `didUpdateValueFor` — sync
   /// CB queue, hence the `Task` hop to the actor.
   func emitStrapHRReading(bpm: Int) {
       let reading = StrapHRReading(bpm: bpm, date: Date())
       Task { await strapReadingActor.broadcast(reading) }
   }

   /// Recomputes HR-sensor presence and broadcasts it. Called from the
   /// CoreBluetooth delegate (connect / disconnect / fail / power-on) — sync CB
   /// queue, hence the `Task` hop to the actor.
   func emitHRSensorPresence() {
       let isConnected = currentHRSensorPresence()
       #if DEBUG
       Logger.bluetooth.debug("[Presence] emit: \(isConnected)")
       #endif
       Task { await presenceActor.broadcast(isConnected) }
   }
   
   /// Whether Bluetooth is powered on — async because the actor needs `await`.
   public var isPoweredOn: Bool {
       get async { await statusActor.isPoweredOn }
   }
   
   /// Whether a scan is running — async because the actor needs `await`.
   public var isScanning: Bool {
       get async { await scanActor.isScanning }
   }
   
   /// The current Bluetooth system status.
   public var currentStatus: BluetoothStatus {
       get async { await statusActor.status }
   }
   
   /// Triggers the manager's initialization.
   public func initializeBluetooth() async {
       Logger.bluetooth.info("[DefaultCentralManager] initializeBluetooth()")
       let currentCBState = cbCentralManager.state
       await updateStatusFromCBState(currentCBState)
   }
   
   /// Starts scanning for BLE devices that carry the Heart Rate service.
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
   
   /// Stops scanning for devices.
   public func stopScanning() async {
       cbCentralManager.stopScan()
       await scanActor.finishScanning()
       
       Logger.bluetooth.info("[DefaultCentralManager] scanning stopped")
   }
   
    /// Returns the devices currently connected to iOS that carry the given services.
    public func getConnectedPeripherals() async -> [CBPeripheral] {
        return cbCentralManager.retrieveConnectedPeripherals(withServices: [
            Gatt.Service.heartRate,
            Gatt.Service.weightScale
        ])
    }
    
   /// Connects to the chosen device.
   public func connect(to peripheral: CBPeripheral) async throws {
       guard await statusActor.isPoweredOn else {
           throw BluetoothError.notPoweredOn
       }
       
       /// Stop scanning before connecting.
       await stopScanning()
       
       /// Start the connection — the result arrives in a delegate callback.
       cbCentralManager.connect(peripheral)
   }
   
   /// Disconnects the given device.
    public func disconnect(_ peripheral: CBPeripheral) async {
       cbCentralManager.cancelPeripheralConnection(peripheral)
   }
    
    public func checkConnectedDevicesFirst() async -> [CBPeripheral] {
        cbCentralManager.retrieveConnectedPeripherals(withServices: [
            Gatt.Service.heartRate
        ])
    }

    // MARK: - Workout sensor hold

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

    // MARK: - BLE diagnostics (why did the strap drop / was data flowing)

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
   
   /// Maps `CBManagerState` to `BluetoothStatus` and updates the actor.
   public func updateStatusFromCBState(_ cbState: CBManagerState) async {
       let newStatus = mapCBStateToBluetoothStatus(cbState)
       await statusActor.updateStatus(newStatus)
       
       Logger.bluetooth.info("[DefaultCentralManager] status: \(String(describing: cbState)) → \(String(describing: newStatus))")
   }
   
   /// Maps `CBManagerState` to `BluetoothStatus`.
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
