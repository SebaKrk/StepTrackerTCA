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
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("🔄 WCSession activation completed with state: \(activationState.rawValue)")

        Task {
            if let error = error {
                print("❌ WCSession activation error: \(error.localizedDescription)")
                await statusActor.updateStatus(.unknown)
                return
            }

            switch activationState {
            case .activated:
                print("✅ WCSession activated successfully")
                let status = await checkConnectionStatus()
                print("📊 Final status: \(status)")
            case .inactive:
                print("⚠️ WCSession inactive")
                await statusActor.updateStatus(.unknown)
            case .notActivated:
                print("❌ WCSession not activated")
                await statusActor.updateStatus(.unknown)
            @unknown default:
                print("❓ Unknown WCSession activation state")
                await statusActor.updateStatus(.unknown)
            }
        }
    }

    /// Called when the session becomes inactive. iOS only.
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("📴 WCSession became inactive")
        Task { await statusActor.updateStatus(.unknown) }
    }

    /// Called when the session deactivates. Reactivates automatically. iOS only.
    public func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 WCSession deactivated - reactivating...")
        Task { await statusActor.updateStatus(.unknown) }
        session.activate()
    }
    #endif

    /// Called when the reachability of the paired device changes.
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("🔄 Watch reachability changed: \(session.isReachable)")
        Task {
            let status = await checkConnectionStatus()
            print("📊 New status after reachability change: \(status)")
        }
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
            print("⚠️ decodeAndYield: failed to decode WatchWorkoutEvent from message")
            return
        }
        print("📨 decodeAndYield: received event → \(event)")
        continuationLock.withLock {
            _eventContinuation?.yield(event)
        }
    }
}
