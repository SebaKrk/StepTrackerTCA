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
/// - Sending live HR readings back to iPhone (`hrReading`)
///
/// Implemented directly on `WCSession` — does not depend on HealthHub.
struct WatchConnectivityClientAW {

    /// Sends a workout event to the paired iPhone.
    var sendWorkoutEvent: @Sendable (WatchWorkoutEvent) async -> Void

    /// A stream of incoming workout events from the paired iPhone.
    var incomingEventStream: @Sendable () -> AsyncStream<WatchWorkoutEvent>

    /// Transfers the workout log file to the paired iPhone via `WCSession.transferFile()`.
    /// The system queues the transfer and delivers it when the devices are in range.
    var transferLogFile: @Sendable () async -> Void
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
            let url = await WorkoutFileLogger.shared.currentFileURL()
            guard WCSession.default.activationState == .activated else {
                Logger.wc.error("[WatchSession] transferLogFile — session not activated")
                return
            }
            Logger.wc.info("[WatchSession] transferLogFile → \(url.lastPathComponent)")
            WCSession.default.transferFile(url, metadata: ["type": "workoutLog"])
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
        if let error {
            Logger.wc.error("[WatchSession] activation failed — state=\(activationState.rawValue), error=\(error.localizedDescription)")
        } else {
            Logger.wc.info("[WatchSession] activated — state=\(activationState.rawValue)")
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

    // MARK: - Private

    private func decodeAndYield(_ dict: [String: Any]) {
        guard let data = dict[Self.messageKey] as? Data,
              let event = try? JSONDecoder().decode(WatchWorkoutEvent.self, from: data)
        else {
            Logger.wc.error("[WatchSession] failed to decode event from message")
            return
        }
        if case .workoutTick = event { } else {
            Logger.wc.info("[WatchSession] received event → \(String(describing: event))")
        }
        continuation?.yield(event)
    }
}
