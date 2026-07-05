//
//  WatchConnectivity+Delegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import OSLog
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

        // Run cleanup synchronously here to avoid capturing non-Sendable `WCSession`
        // in the async Task below (Swift 6 strict concurrency).
        if activationState == .activated, error == nil {
            cleanupOutstandingTransfers(session)
        }

        Task {
            if let error = error {
                Logger.wc.error("activation error: \(error.localizedDescription)")
                await statusActor.updateStatus(.unknown)
                return
            }

            switch activationState {
            case .activated:
                let status = await checkConnectionStatus()
                Logger.wc.info("WCSession activated — status: \(String(describing: status))")
            case .inactive:
                Logger.wc.notice("WCSession inactive after activation")
                await statusActor.updateStatus(.unknown)
            case .notActivated:
                Logger.wc.error("WCSession not activated")
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
        Logger.wc.info("WCSession deactivated — reactivating")
        Task { await statusActor.updateStatus(.unknown) }
        session.activate()
    }
    #endif

    /// Called when the reachability of the paired device changes.
    public func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        // .debug instead of .info — reachability flips frequently during end-flow
        // (BT/WC renegotiation). Console.app with --level debug still shows it.
        // Release builds: compile-stripped, zero cost.
        Logger.wc.debug("reachability → \(isReachable)")
        Task {
            await WorkoutFileLogger.shared.log("[Disconnect] WC reachability → \(isReachable)")
        }
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

    // MARK: - File Transfer

    /// Receives a file transferred from the Watch (e.g. workout log).
    /// Saves it to the iPhone app's Documents directory with a timestamp in the filename.
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let type = file.metadata?["type"] as? String, type == "workoutLog" else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let dest = docs.appendingPathComponent("watch_log_\(timestamp).txt")
        do {
            try FileManager.default.copyItem(at: file.fileURL, to: dest)
            Logger.wc.info("received Watch log → saved: \(dest.lastPathComponent)")
        } catch {
            Logger.wc.error("failed to save Watch log: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Decodes a `WatchWorkoutEvent` from a message dictionary and yields it to the stream.
    private func decodeAndYield(_ dict: [String: Any]) {
        guard let data = dict[Self.messageKey] as? Data,
              let event = try? JSONDecoder().decode(WatchWorkoutEvent.self, from: data)
        else {
            Logger.wc.error("decodeAndYield: failed to decode WatchWorkoutEvent")
            return
        }
        // Skip high-frequency tick events to keep logs readable.
        if case .workoutTick = event { } else {
            Logger.wc.info("received event → \(String(describing: event))")
        }
        yieldIncomingEvent(event)
    }
}
