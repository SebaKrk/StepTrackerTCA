//
//  WatchConnectivityClientAW.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import OSLog
import SharedModels
import WatchConnectivity

/// TCA dependency for WatchConnectivity on the Apple Watch side.
///
/// Provides a Watch-specific interface for:
/// - Receiving workout control events from iPhone (`workoutStarted`, `workoutEnded`, etc.)
/// - Sending `workoutSaved(uuid)` notification to iPhone after `finishWorkout()`
/// - Transferring log files for diagnostic purposes
///
/// Note: HR readings flow via HealthKit mirroring channel (`sendToRemoteWorkoutSession`),
/// NOT WatchConnectivity — per WWDC25 #322 R2.
///
/// Implemented directly on `WCSession` — does not depend on HealthHub.
struct WatchConnectivityClientAW {

    /// Sends a workout event to the paired iPhone.
    var sendWorkoutEvent: @Sendable (WatchWorkoutEvent) async -> Void

    /// A stream of incoming workout events from the paired iPhone.
    var incomingEventStream: @Sendable () -> AsyncStream<WatchWorkoutEvent>

    /// Closes the finished workout's log file and queues it for the paired iPhone.
    /// The system delivers it when the devices are in range.
    var transferLogFile: @Sendable () async -> Void

    /// Transfers every finished log file that is not already on its way to the paired iPhone.
    ///
    /// Used on Watch app launch to deliver logs from previous (possibly crashed)
    /// sessions that never reached the normal `.stop` flow. A file is deleted on the
    /// Watch once the system confirms its delivery, so it is sent once.
    var transferAllLogFiles: @Sendable () async -> Void

    /// A stream of what the paired iPhone pushes about readiness: a score, or the lock.
    var readinessDeliveryStream: @Sendable () -> AsyncStream<ReadinessDelivery>

    /// The most recent delivery already held by `WCSession`, if any.
    ///
    /// Read on appear so a freshly launched Watch app shows the last known
    /// value immediately instead of waiting for the next push.
    var latestReadinessDelivery: @Sendable () -> ReadinessDelivery?
}

// MARK: - Dependency Registration

extension DependencyValues {
    var watchConnectivityClientAW: WatchConnectivityClientAW {
        get { self[WatchConnectivityClientAWKey.self] }
        set { self[WatchConnectivityClientAWKey.self] = newValue }
    }
}

private enum WatchConnectivityClientAWKey: DependencyKey {
    static let liveValue: WatchConnectivityClientAW = {
        let session = WatchSession.shared
        return WatchConnectivityClientAW {
            await session.send($0)
        } incomingEventStream: {
            session.eventStream
        } transferLogFile: {
            guard WorkoutLogStore.isRecordingEnabled else { return }
            // Sealed first: a file still being written must never be sent or deleted.
            guard let url = await WorkoutFileLogger.shared.sealCurrentFile() else { return }
            await session.transferLog(at: url)
        } transferAllLogFiles: {
            await session.transferPendingLogs()
        } readinessDeliveryStream: {
            session.readinessStream
        } latestReadinessDelivery: {
            session.latestDelivery()
        }
    }()
}

// MARK: - WatchSession

/// Manages the `WCSession` lifecycle and event stream for the Watch App.
///
/// Activates the session on init and forwards received messages
/// into `eventStream` for consumption by TCA features.
private final class WatchSession: NSObject, WCSessionDelegate, @unchecked Sendable {

    static let shared = WatchSession()

    /// Mutable continuation — replaced on each `eventStream` access so that
    /// every `incomingEventStream()` call returns a **fresh** `AsyncStream`.
    /// Without this, all callers share the same stream object and only the
    /// first `for await` consumer receives events (single-consumer limitation).
    private var continuation: AsyncStream<WatchWorkoutEvent>.Continuation?
    private static let messageKey = "watchWorkoutEvent"

    /// Returns a new `AsyncStream` each time it is accessed.
    /// The previous continuation is finished so the old consumer terminates cleanly.
    var eventStream: AsyncStream<WatchWorkoutEvent> {
        continuation?.finish()
        let (stream, newContinuation) = AsyncStream<WatchWorkoutEvent>.makeStream()
        continuation = newContinuation
        return stream
    }

    /// Mutable continuation for readiness deliveries — same single-consumer
    /// pattern as `continuation` above.
    private var readinessContinuation: AsyncStream<ReadinessDelivery>.Continuation?

    /// Returns a new `AsyncStream` each time it is accessed, matching `eventStream`.
    var readinessStream: AsyncStream<ReadinessDelivery> {
        readinessContinuation?.finish()
        let (stream, newContinuation) = AsyncStream<ReadinessDelivery>.makeStream()
        readinessContinuation = newContinuation
        return stream
    }

    /// Decodes the delivery currently held in `WCSession.receivedApplicationContext`.
    func latestDelivery() -> ReadinessDelivery? {
        decodeDelivery(WCSession.default.receivedApplicationContext)
    }

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send

    /// Encodes and sends a `WatchWorkoutEvent` to the paired iPhone.
    ///
    /// Uses `sendMessage` when reachable, falls back to `transferUserInfo`.
    func send(_ event: WatchWorkoutEvent) async {
        guard WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(event) else {
            Logger.wc.error("[WatchSession] send: session not activated or encode failed for \(String(describing: event))")
            return
        }
        let message = [Self.messageKey: data]
        if WCSession.default.isReachable {
            Logger.wc.info("[WatchSession] sendMessage → \(String(describing: event))")
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                Logger.wc.error("[WatchSession] sendMessage failed (\(error.localizedDescription)) — falling back to transferUserInfo")
                WCSession.default.transferUserInfo(message)
            }
        } else {
            Logger.wc.info("[WatchSession] not reachable — transferUserInfo → \(String(describing: event))")
            WCSession.default.transferUserInfo(message)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let stateRaw = activationState.rawValue
        let errorDescription = error?.localizedDescription
        if let errorDescription {
            Logger.wc.error("[WatchSession] activation failed — state=\(stateRaw), error=\(errorDescription)")
            Task {
                await WorkoutFileLogger.shared.log("[WC] activation FAILED — state=\(stateRaw), error=\(errorDescription)")
            }
        } else {
            Logger.wc.info("[WatchSession] activated — state=\(stateRaw)")
            // The context is readable only now; it may hold a choice made while the Watch app was closed.
            applyLogRecording(from: session.receivedApplicationContext)
            Task {
                await WorkoutFileLogger.shared.log("[WC] activated — state=\(stateRaw)")
                await transferPendingLogs()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decodeAndYield(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        decodeAndYield(message)
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decodeAndYield(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyLogRecording(from: applicationContext)
        guard let delivery = decodeDelivery(applicationContext) else { return }
        Logger.wc.info("[WatchSession] received readiness delivery")
        readinessContinuation?.yield(delivery)
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        guard fileTransfer.file.metadata?[Self.logTypeKey] as? String == Self.logType else { return }
        let name = fileTransfer.file.fileURL.lastPathComponent
        if let error {
            Logger.wc.error("[WatchSession] log transfer failed — \(name): \(error.localizedDescription)")
            return
        }
        // Delivered — the iPhone holds it now, so the Watch copy can go and is never sent twice.
        try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        Logger.wc.info("[WatchSession] log delivered and removed — \(name)")
    }

    // MARK: - Log files

    /// Queues one finished log file for the paired iPhone.
    func transferLog(at url: URL) {
        guard WCSession.default.activationState == .activated else {
            Logger.wc.error("[WatchSession] transferLog — session not activated")
            return
        }
        Logger.wc.info("[WatchSession] transferLog → \(url.lastPathComponent)")
        WCSession.default.transferFile(url, metadata: [
            Self.logTypeKey: Self.logType,
            "startedAt": Date(),
            "fileName": url.lastPathComponent
        ])
    }

    /// Queues every finished log that is not already on its way; the file being written is left alone.
    func transferPendingLogs() async {
        guard WorkoutLogStore.isRecordingEnabled,
              WCSession.default.activationState == .activated else { return }
        // Listed by the logger in one step, so a workout file started meanwhile cannot be queued.
        let finished = await WorkoutFileLogger.shared.finishedLogFiles(now: Date())
        let queued = Set(WCSession.default.outstandingFileTransfers.map { $0.file.fileURL.lastPathComponent })
        let pending = finished.filter { !queued.contains($0.lastPathComponent) }
        Logger.wc.info("[WatchSession] transferPendingLogs → \(pending.count) files")
        for file in pending {
            transferLog(at: file)
        }
    }

    /// Stores the iPhone's choice; switching off cancels queued logs and deletes the ones on the Watch.
    private func applyLogRecording(from context: [String: Any]) {
        guard let isEnabled = context[WatchContextKey.workoutLogRecording] as? Bool else { return }
        UserDefaults.standard.set(isEnabled, forKey: AppStorageKeys.workoutLogRecording)
        // Debug builds always record, so this never deletes a developer's logs.
        guard !WorkoutLogStore.isRecordingEnabled else { return }
        for transfer in WCSession.default.outstandingFileTransfers
        where transfer.file.metadata?[Self.logTypeKey] as? String == Self.logType {
            transfer.cancel()
        }
        // Through the logger, so a line in flight cannot bring a file back.
        Task { await WorkoutFileLogger.shared.removeAll() }
    }

    // MARK: - Private

    /// Metadata key telling the iPhone what kind of file arrived.
    private static let logTypeKey = "type"

    /// Metadata value marking a workout log.
    private static let logType = "workoutLog"

    private func decodeAndYield(_ dict: [String: Any]) {
        guard let data = dict[Self.messageKey] as? Data,
              let event = try? JSONDecoder().decode(WatchWorkoutEvent.self, from: data)
        else {
            Logger.wc.error("[WatchSession] failed to decode event from message")
            Task {
                await WorkoutFileLogger.shared.log("[WC RX] decode FAILED")
            }
            return
        }
        // Skip workoutTick (high-frequency, would flood the log file).
        if case .workoutTick = event { } else {
            let eventDescription = String(describing: event)
            Logger.wc.info("[WatchSession] received event → \(eventDescription)")
            Task {
                await WorkoutFileLogger.shared.log("[WC RX] \(eventDescription)")
            }
        }
        continuation?.yield(event)
    }

    /// The lock wins over a snapshot: a context carrying both must not show a score.
    private func decodeDelivery(_ dict: [String: Any]) -> ReadinessDelivery? {
        if dict[WatchContextKey.readinessLocked] as? Bool == true {
            return .locked
        }
        return decodeSnapshot(dict).map(ReadinessDelivery.snapshot)
    }

    private func decodeSnapshot(_ dict: [String: Any]) -> ReadinessSnapshot? {
        guard let data = dict[WatchContextKey.readinessSnapshot] as? Data,
              let snapshot = try? JSONDecoder().decode(ReadinessSnapshot.self, from: data)
        else { return nil }

        guard snapshot.schemaVersion == ReadinessSnapshot.currentSchemaVersion else {
            Logger.wc.error("[WatchSession] readiness snapshot schema \(snapshot.schemaVersion) not supported")
            return nil
        }
        return snapshot
    }
}
