//
//  ExtendedRuntimeClient.swift
//  WorkoutMirror Watch App
//

import ComposableArchitecture
import WatchKit

/// TCA dependency that manages a `WKExtendedRuntimeSession` of type `.workoutProcessing`.
///
/// Keeps the Watch App active in the foreground during a workout —
/// prevents the system from suspending it after ~70 s of inactivity.
/// Requires `WKBackgroundModes: ["workout-processing"]` in Info.plist.
struct ExtendedRuntimeClient: Sendable {
    var start: @Sendable () async -> Void
    var stop: @Sendable () async -> Void
}

// MARK: - Dependency

extension DependencyValues {
    var extendedRuntimeClient: ExtendedRuntimeClient {
        get { self[ExtendedRuntimeClientKey.self] }
        set { self[ExtendedRuntimeClientKey.self] = newValue }
    }
}

private enum ExtendedRuntimeClientKey: DependencyKey {
    static let liveValue: ExtendedRuntimeClient = {
        let manager = ExtendedRuntimeManager()
        return ExtendedRuntimeClient(
            start: { manager.start() },
            stop: { manager.stop() }
        )
    }()
}

// MARK: - Manager

private final class ExtendedRuntimeManager: NSObject, WKExtendedRuntimeSessionDelegate, @unchecked Sendable {

    private var session: WKExtendedRuntimeSession?

    func start() {
        session?.invalidate()
        let newSession = WKExtendedRuntimeSession()
        newSession.delegate = self
        newSession.start()
        session = newSession
        print("⌚️ ExtendedRuntimeSession: start requested")
    }

    func stop() {
        session?.invalidate()
        session = nil
        print("⌚️ ExtendedRuntimeSession: stopped")
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedRuntimeSession: active")
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedRuntimeSession: will expire")
    }

    func extendedRuntimeSession(
        _ session: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: (any Error)?
    ) {
        print("⌚️ ExtendedRuntimeSession: invalidated reason=\(reason.rawValue) error=\(String(describing: error))")
    }
}
