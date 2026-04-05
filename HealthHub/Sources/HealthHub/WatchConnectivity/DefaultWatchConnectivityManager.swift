//
//  DefaultWatchConnectivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import Foundation
import SharedModels
import WatchConnectivity

/// Default implementation of `WatchConnectivityManager` backed by `WCSession`.
///
/// Manages the full lifecycle of a WatchConnectivity session:
/// activating the session, tracking connection status via `WatchConnectivityStatusActor`,
/// and exchanging `WatchWorkoutEvent` messages with the paired device.
///
/// Incoming messages (from both `sendMessage` and `transferUserInfo`) are decoded
/// and forwarded through `incomingWorkoutEventStream`.
@preconcurrency
public final class DefaultWatchConnectivityManager: NSObject, WatchConnectivityManager, @unchecked Sendable {

    // MARK: - Internal

    /// Key used to encode/decode `WatchWorkoutEvent` in WCSession message dictionaries.
    static let messageKey = "watchWorkoutEvent"

    /// The underlying WCSession instance.
    private var session: WCSession?

    /// Actor responsible for thread-safe connection status updates.
    let statusActor = WatchConnectivityStatusActor()

    // MARK: - Incoming Event Stream

    /// Lock protecting `_eventContinuation` across delegate callbacks and stream subscriptions.
    let continuationLock = NSLock()

    /// Current continuation backing `incomingWorkoutEventStream`.
    ///
    /// Replaced on each call to `incomingWorkoutEventStream` so that every new
    /// `for await` subscription (e.g. second workout run) gets a fresh stream.
    /// The previous continuation is finished first to cleanly terminate any
    /// lingering iterator from the previous session.
    var _eventContinuation: AsyncStream<WatchWorkoutEvent>.Continuation?

    /// A stream of `WatchWorkoutEvent` values received from the paired device.
    ///
    /// Each access creates a new `AsyncStream` backed by a fresh continuation,
    /// finishing the previous one. This prevents the "stale iterator" problem
    /// where a second `for await` loop on the same stream receives no events
    /// after the first loop was cancelled by TCA's `cancellable(id:)` mechanism.
    public var incomingWorkoutEventStream: AsyncStream<WatchWorkoutEvent> {
        let (stream, continuation) = AsyncStream<WatchWorkoutEvent>.makeStream()
        continuationLock.withLock {
            _eventContinuation?.finish()
            _eventContinuation = continuation
        }
        return stream
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        print("🍎 🟢 Created DefaultWatchConnectivityManager")
    }

    deinit {
        print("🪦 -> ❌ DefaultWatchConnectivityManager deinit")
    }

    // MARK: - WatchConnectivityManager

    /// Whether WatchConnectivity is supported on this device.
    public var isSupported: Bool {
        get async { WCSession.isSupported() }
    }

    /// Whether an Apple Watch is currently paired. Always returns `false` on watchOS.
    public var isPaired: Bool {
        get async {
            #if os(iOS)
            return session?.isPaired ?? false
            #else
            return false
            #endif
        }
    }

    /// Whether the companion Watch app is installed. Always returns `false` on watchOS.
    public var isWatchAppInstalled: Bool {
        get async {
            #if os(iOS)
            return session?.isWatchAppInstalled ?? false
            #else
            return false
            #endif
        }
    }

    /// Whether the paired device is currently reachable.
    public var isReachable: Bool {
        get async { session?.isReachable ?? false }
    }

    /// The current connection status.
    public var currentStatus: WatchConnectivityStatus {
        get async { await statusActor.status }
    }

    /// Activates the `WCSession` and begins monitoring connection status.
    public func initializeWatchConnectivity() async {
        print("🍎 DefaultWatchConnectivityManager: initializeWatchConnectivity() called")

        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported")
            await statusActor.updateStatus(.notSupported)
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("🔄 WCSession activation started...")
    }

    /// Evaluates and returns the current connection status.
    public func checkConnectionStatus() async -> WatchConnectivityStatus {
        guard WCSession.isSupported() else {
            await statusActor.updateStatus(.notSupported)
            return .notSupported
        }

        guard let session else {
            await statusActor.updateStatus(.unknown)
            return .unknown
        }

        #if os(iOS)
        if session.isPaired {
            await statusActor.updateStatus(.ready)
            return .ready
        } else {
            await statusActor.updateStatus(.notPaired)
            return .notPaired
        }
        #else
        await statusActor.updateStatus(.ready)
        return .ready
        #endif
    }

    /// Deactivates the session, resets status, and finishes the event stream.
    public func stopWatchConnectivity() async {
        print("🛑 Stopping WatchConnectivity...")
        session?.delegate = nil
        session = nil
        await statusActor.updateStatus(.unknown)
        continuationLock.withLock {
            _eventContinuation?.finish()
            _eventContinuation = nil
        }
    }

    // MARK: - Sending Events

    /// Sends a `WatchWorkoutEvent` to the paired device.
    ///
    /// Uses `sendMessage` for immediate delivery when reachable,
    /// otherwise falls back to `transferUserInfo` for guaranteed delivery.
    /// - Throws: `WatchConnectivityError.sessionNotActivated` if the session is not active.
    public func sendWorkoutEvent(_ event: WatchWorkoutEvent) async throws {
        print("📡 sendWorkoutEvent: \(event)")
        guard let session, session.activationState == .activated else {
            print("❌ sendWorkoutEvent: session not activated")
            throw WatchConnectivityError.sessionNotActivated
        }
        let data = try JSONEncoder().encode(event)
        let message = [Self.messageKey: data]
        if session.isReachable {
            print("📡 sendWorkoutEvent: sending via sendMessage (reachable)")
            session.sendMessage(message, replyHandler: nil) { error in
                print("📡 sendMessage failed (\(error.localizedDescription)), falling back to transferUserInfo")
                session.transferUserInfo(message)
            }
        } else {
            print("📡 sendWorkoutEvent: sending via transferUserInfo (not reachable)")
            session.transferUserInfo(message)
        }
    }
}
