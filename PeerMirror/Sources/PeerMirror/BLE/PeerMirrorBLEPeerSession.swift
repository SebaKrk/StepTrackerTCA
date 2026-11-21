//
//  PeerMirrorBLEPeerSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth
import Foundation
import OSLog
import SharedModels

/// Peer role in Bluetooth Low Energy — used by the iPhone (the athlete joining a class).
///
/// **Responsibilities**:
/// - Scans for the iPad's broadcast (`CBCentralManager.scanForPeripherals(withServices:)`)
/// - Proximity gate on RSSI (`> -75 dBm` ~10m)
/// - Connect + discover services + characteristics
/// - Subscribes to the HR Stream characteristic (presence signaling to the peripheral)
/// - **Reads the Discovery Info characteristic** to get the iPad's displayName, used
///   as `nick` in the `.connected` event (`deviceID` = `peripheral.identifier`, BLE-level)
/// - Sends `HRSamplePayload` through `writeValue(_, for:, type: .withoutResponse)`
/// - Auto-reconnect with exponential backoff (1s → 2s → 4s → 8s → cap 30s)
///
/// **`.connected` emit timing**: AFTER `didUpdateValueFor(discoveryInfo)` — so the reducer
/// gets the real displayName, not a placeholder. Falls back to the UUID when the read fails
/// or the discoveryInfo characteristic is missing (defensive — the reducer still gets the event).
///
/// **Lifecycle**: created in `PeerMirrorService.startBrowsing`, dropped in `stopBrowsing`.
///
/// Background mode: `bluetooth-central` — heart rate keeps reaching the coach's iPad with the screen off.
public final class PeerMirrorBLEPeerSession: NSObject, @unchecked Sendable {

    // MARK: - Logger

    static let logger = Logger(
        subsystem: "com.ss.WorkoutMirrorLive",
        category: "BLE-Peer"
    )

    /// RSSI threshold for the proximity gate. -75 dBm ≈ 10m (the usual reach of a gym room).
    /// A weaker signal = the user is not in the room, so the advertisement is ignored.
    static let rssiThreshold: Int = -75

    /// Max delay before the next reconnect attempt (after `lostPeripheralResetTimeoutSeconds`).
    static let maxReconnectDelaySeconds: TimeInterval = 30

    /// Timeout for `central.connect()` — Apple's default is ~30s. We cancel after 8s
    /// to trigger the reconnect flow sooner when the peripheral vanished mid-connect.
    /// 8s leaves a ~4x buffer over a healthy BLE handshake (~2s), yet is 3-4x faster than Apple.
    static let connectTimeoutSeconds: TimeInterval = 8

    // MARK: - BLE

    let centralManager: CBCentralManager
    /// CBPeripheral — an NSObject, not Sendable. Apple's CBCentralManager guarantees thread-safety
    /// for callbacks, so `nonisolated(unsafe)` is justified per Swift Concurrency Course.
    nonisolated(unsafe) var hostPeripheral: CBPeripheral?
    nonisolated(unsafe) var hrCharacteristic: CBCharacteristic?

    // MARK: - Reconnect state

    private var reconnectDelaySeconds: TimeInterval = 1
    private var shouldAutoReconnect = true

    /// Identifier of the last connected host. Set in `didConnect`, used
    /// for the pending-connect reconnect (`retrievePeripherals`) instead of a scan + RSSI
    /// gate — back in range → iOS completes the connection by itself.
    nonisolated(unsafe) var knownHostID: UUID?

    /// Active connect watchdog. Cancelled in `didConnect` / `didFailToConnect`.
    /// Without it a stale `connect()` can hang ~30s before Apple's `didFailToConnect`.
    var connectTimeoutTask: Task<Void, Never>?

    // MARK: - Callbacks

    let onPeerEvent: @Sendable (PeerEvent) -> Void

    // MARK: - Init

    public init(
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void
    ) {
        self.onPeerEvent = onPeerEvent
        self.centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        self.centralManager.delegate = self
    }

    // MARK: - Public

    public func stop() {
        // Defensive: a goodbye still awaiting its ACK must not hang forever
        // once the link is being torn down.
        resumeGoodbye(acked: false, note: "stop() during wait")
        shouldAutoReconnect = false
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        if let peripheral = hostPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        hostPeripheral = nil
        hrCharacteristic = nil
        knownHostID = nil
        Self.logger.info("Peer stopped")
        fileLog("peer stopped (auto-reconnect off)")
    }

    public func send(_ payload: HRSamplePayload) {
        guard let peripheral = hostPeripheral,
              let characteristic = hrCharacteristic,
              peripheral.state == .connected
        else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            // writeWithoutResponse: idempotent stream, no ACK overhead, a lost sample is fine.
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } catch {
            Self.logger.error("Encode failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Goodbye (ACK-confirmed)

    /// Continuation parked by `sendGoodbye` until the host ACKs the write
    /// (`didWriteValueFor`) or the timeout fires. Lock-guarded — the ACK
    /// callback, the timeout task and `stop()` can race to resume it.
    private let goodbyeLock = NSLock()
    private var goodbyeContinuation: CheckedContinuation<Bool, Never>?
    private var goodbyeTimeoutTask: Task<Void, Never>?

    /// Sends the goodbye `.withResponse` and suspends until the host ACKs
    /// (ATT Write Response) or `timeout` elapses — so the caller can tear the
    /// link down without racing the delivery. Returns `true` on ACK. Worst
    /// case (no ACK) equals the old behavior: host falls back to grace.
    public func sendGoodbye(_ payload: HRSamplePayload, timeout: Duration = .seconds(1)) async -> Bool {
        guard let peripheral = hostPeripheral,
              let characteristic = hrCharacteristic,
              peripheral.state == .connected
        else {
            fileLog("goodbye SKIPPED — not connected (host falls back to 5 min grace)")
            return false
        }
        guard let data = try? JSONEncoder().encode(payload) else {
            Self.logger.error("Goodbye encode failed")
            return false
        }

        fileLog("goodbye sent (withResponse) — awaiting ACK")
        return await withCheckedContinuation { continuation in
            goodbyeLock.withLock { goodbyeContinuation = continuation }
            goodbyeTimeoutTask = Task { [weak self, timeout] in
                try? await Task.sleep(for: timeout)
                self?.resumeGoodbye(acked: false, note: "timeout — link presumed dead")
            }
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    /// Single-resume gate for the goodbye continuation (ACK / timeout / stop race).
    func resumeGoodbye(acked: Bool, note: String) {
        let continuation = goodbyeLock.withLock {
            let parked = goodbyeContinuation
            goodbyeContinuation = nil
            return parked
        }
        guard let continuation else { return }
        goodbyeTimeoutTask?.cancel()
        goodbyeTimeoutTask = nil
        fileLog(acked ? "goodbye ACK — host confirmed, tile removed" : "goodbye NOT confirmed (\(note))")
        continuation.resume(returning: acked)
    }

    // MARK: - Private (scan/reconnect)

    func startScanning() {
        guard centralManager.state == .poweredOn, !centralManager.isScanning else {
            fileLog("scan SKIPPED (state=\(centralManager.state.rawValue) scanning=\(centralManager.isScanning))")
            return
        }
        centralManager.scanForPeripherals(
            withServices: [BLEServiceConstants.gymRoomServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        Self.logger.info("Scanning started")
        fileLog("scan started")
    }

    /// Pending connect to the known host. iOS completes the connection once the host is back
    /// in range — no scan, RSSI gate or watchdog (`connect()` to a known
    /// peripheral does not expire). Returns `false` when the host is unknown (first
    /// run) — the caller scans then.
    func connectKnownHostIfPossible() -> Bool {
        guard centralManager.state == .poweredOn,
              let knownHostID,
              let peripheral = centralManager.retrievePeripherals(withIdentifiers: [knownHostID]).first
        else { return false }
        fileLog("pending connect to known host \(knownHostID.uuidString.prefix(8)) (no scan/gate)")
        hostPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        return true
    }

    func scheduleReconnect() {
        guard shouldAutoReconnect else {
            fileLog("reconnect SKIPPED (auto-reconnect off)")
            return
        }
        // Known host → pending connect right away, no backoff/scan/gate.
        if connectKnownHostIfPossible() { return }
        let delay = reconnectDelaySeconds
        reconnectDelaySeconds = min(reconnectDelaySeconds * 2, Self.maxReconnectDelaySeconds)
        Self.logger.info("Reconnect scheduled in \(delay, format: .fixed(precision: 1))s")
        fileLog("reconnect scheduled in \(String(format: "%.1f", delay))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startScanning()
        }
    }

    func resetReconnectBackoff() {
        reconnectDelaySeconds = 1
    }

    /// Watchdog on `central.connect()` — Apple can hang ~30s before `didFailToConnect`
    /// when the peripheral vanished mid-connect. After `Self.connectTimeoutSeconds` it calls
    /// `cancelPeripheralConnection` by hand to trigger our reconnect flow.
    func scheduleConnectTimeout(for peripheral: CBPeripheral) {
        let peripheralID = peripheral.identifier
        connectTimeoutTask?.cancel()
        connectTimeoutTask = Task { @MainActor [weak self, peripheralID] in
            try? await Task.sleep(for: .seconds(Self.connectTimeoutSeconds))
            guard !Task.isCancelled,
                  let self,
                  let hostPeripheral = self.hostPeripheral,
                  hostPeripheral.identifier == peripheralID,
                  hostPeripheral.state != .connected
            else { return }
            Self.logger.warning(
                "connect() timeout after \(Self.connectTimeoutSeconds, format: .fixed(precision: 0))s — forcing cancel to trigger reconnect"
            )
            self.fileLog("connect() TIMEOUT \(Int(Self.connectTimeoutSeconds))s — forcing cancel")
            self.centralManager.cancelPeripheralConnection(hostPeripheral)
        }
    }

    // MARK: - Diagnostics (DEBUG only)

    /// Mirrors key BLE lifecycle events into the shared workout file log so they
    /// interleave with HR readings — making reconnect failures visible without a Mac.
    /// No-op in release. Fire-and-forget Task: sub-second ordering not guaranteed,
    /// but every line carries an `HH:mm:ss` timestamp.
    #if DEBUG
    func fileLog(_ message: String) {
        Task { await WorkoutFileLogger.shared.log("[BLE-Peer] \(message)") }
    }
    #else
    func fileLog(_ message: String) {}
    #endif
}
