//
//  WatchConnectivity+Delegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import SharedModels
import WatchConnectivity

extension DefaultWatchConnectivityManager: WCSessionDelegate {

    // MARK: - Session Lifecycle

    /// Called when the WCSession activation attempt completes.
    ///
    /// Resumes `activationContinuation` so that `initializeWatchConnectivity()`
    /// unblocks — only after this point is `isPaired` safe to read.
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Unblock `initializeWatchConnectivity()` regardless of outcome.
        activationContinuation?.resume()
        activationContinuation = nil

        Task {
            if let error = error {
                print("❌ [WC] activation error: \(error.localizedDescription)")
                await statusActor.updateStatus(.unknown)
                return
            }

            switch activationState {
            case .activated:
                let status = await checkConnectionStatus()
                print("✅ [WC] WCSession activated — status: \(status)")
            case .inactive:
                print("⚠️ [WC] WCSession inactive after activation")
                await statusActor.updateStatus(.unknown)
            case .notActivated:
                print("❌ [WC] WCSession not activated")
                await statusActor.updateStatus(.unknown)
            @unknown default:
                await statusActor.updateStatus(.unknown)
            }
        }
    }

    /// Called when the session becomes inactive. iOS only.
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        Task { await statusActor.updateStatus(.unknown) }
    }

    /// Called when the session deactivates. Reactivates automatically. iOS only.
    public func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 [WC] WCSession deactivated — reactivating")
        Task { await statusActor.updateStatus(.unknown) }
        session.activate()
    }
    #endif

    /// Called when the reachability of the paired device changes.
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("🔄 WCSession reachability → \(session.isReachable)")
        Task { await checkConnectionStatus() }
    }

    // MARK: - Receiving Messages

    /// Called when a message arrives via `sendMessage` (no reply handler).
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decodeAndYield(message)
    }

    /// Called when a message arrives via `sendMessage` with a reply handler.
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        decodeAndYield(message)
        replyHandler([:])
    }

    /// Called when data arrives via `transferUserInfo` (guaranteed background delivery).
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decodeAndYield(userInfo)
    }

    // MARK: - Private

    /// Decodes a `WatchWorkoutEvent` from a message dictionary and yields it to the stream.
    private func decodeAndYield(_ dict: [String: Any]) {
        guard let data = dict[Self.messageKey] as? Data,
              let event = try? JSONDecoder().decode(WatchWorkoutEvent.self, from: data)
        else {
            print("⚠️ [WC] decodeAndYield: failed to decode WatchWorkoutEvent")
            return
        }
        // Skip high-frequency tick events to keep logs clean.
        if case .workoutTick = event { } else {
            print("📨 [WC] received event → \(event)")
        }
        continuationLock.withLock {
            _eventContinuation?.yield(event)
        }
    }
}
