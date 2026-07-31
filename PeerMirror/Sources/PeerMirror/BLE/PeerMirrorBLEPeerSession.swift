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

/// Peer role w Bluetooth Low Energy — używana przez iPhone (athlete dołączający do klasy).
///
/// **Responsibilities**:
/// - Scanuje broadcast iPada (`CBCentralManager.scanForPeripherals(withServices:)`)
/// - Proximity gate przez RSSI (`> -75 dBm` ~10m)
/// - Connect + discover services + characteristics
/// - Subscribe do HR Stream characteristic (presence signaling do peripheral)
/// - **Reads Discovery Info characteristic** żeby pozyskać iPad displayName używany
///   jako `nick` w `.connected` evencie (`deviceID` = `peripheral.identifier`, BLE-level)
/// - Wysyła `HRSamplePayload` przez `writeValue(_, for:, type: .withoutResponse)`
/// - Auto-reconnect z exponential backoff (1s → 2s → 4s → 8s → cap 30s)
///
/// **`.connected` emit timing**: PO `didUpdateValueFor(discoveryInfo)` — żeby reducer
/// dostał prawdziwy displayName, nie placeholder. Fallback do UUID gdy read fail
/// lub discoveryInfo characteristic nie znaleziony (defensive — reducer wciąż dostaje event).
///
/// **Lifecycle**: stworzona w `PeerMirrorService.startBrowsing`, dropped w `stopBrowsing`.
public final class PeerMirrorBLEPeerSession: NSObject, @unchecked Sendable {

    // MARK: - Logger

    static let logger = Logger(
        subsystem: "com.ss.WorkoutMirrorLive",
        category: "BLE-Peer"
    )

    /// RSSI threshold dla proximity gate. -75 dBm ≈ 10m (typowy zasięg sali).
    /// Słabszy signal = user nie w sali, ignorujemy advertisement.
    static let rssiThreshold: Int = -75

    /// Max delay przed kolejnym reconnect attempt (po `lostPeripheralResetTimeoutSeconds`).
    static let maxReconnectDelaySeconds: TimeInterval = 30

    /// Timeout dla `central.connect()` — Apple default to ~30s. My cancel'ujemy po 8s
    /// żeby szybciej trigger'ować reconnect flow gdy peripheral zniknął mid-connect.
    /// 8s daje ~4x buffer nad zdrowym BLE handshake (~2s), ale 3-4x szybsze niż Apple.
    static let connectTimeoutSeconds: TimeInterval = 8

    // MARK: - BLE

    let centralManager: CBCentralManager
    /// CBPeripheral — NSObject, nie jest Sendable. Apple CBCentralManager gwarantuje thread-safety
    /// dla callbacks, więc `nonisolated(unsafe)` jest uzasadniony per Swift Concurrency Course.
    nonisolated(unsafe) var hostPeripheral: CBPeripheral?
    nonisolated(unsafe) var hrCharacteristic: CBCharacteristic?

    // MARK: - Reconnect state

    private var reconnectDelaySeconds: TimeInterval = 1
    private var shouldAutoReconnect = true

    /// Identifier ostatnio połączonego hosta. Ustawiany w `didConnect`, używany
    /// do pending-connect reconnectu (`retrievePeripherals`) zamiast skanu + RSSI
    /// gate — wraca w zasięg → iOS dokańcza połączenie sam.
    nonisolated(unsafe) var knownHostID: UUID?

    /// Active connect watchdog. Cancel'owany w `didConnect` / `didFailToConnect`.
    /// Bez tego stale `connect()` może wisieć ~30s przed Apple `didFailToConnect`.
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
            // writeWithoutResponse: idempotent stream, brak ACK overhead, zgubiony sample OK.
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

    /// Pending connect do znanego hosta. iOS dokańcza połączenie gdy host wróci
    /// w zasięg — bez skanu, RSSI gate'u i watchdoga (`connect()` do znanego
    /// peripherala nie wygasa). Zwraca `false` gdy hosta nie znamy (pierwsze
    /// uruchomienie) — wtedy caller skanuje.
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
        // Znany host → pending connect od ręki, bez backoffu/skanu/gate.
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

    /// Watchdog na `central.connect()` — Apple może wisieć ~30s przed `didFailToConnect`
    /// gdy peripheral zniknął mid-connect. Po `Self.connectTimeoutSeconds` manualnie
    /// `cancelPeripheralConnection` żeby triggrować nasz reconnect flow.
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
