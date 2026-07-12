//
//  HKWorkoutSession+SendWithTimeout.swift
//  SharedModels
//
//  Created by Sebastian Ściuba
//

import Foundation
import HealthKit
import os

#if os(iOS) || os(watchOS)

/// Failure surface for `sendToRemoteWorkoutSession(data:timeout:retries:)`.
public enum MirroringSendError: Error, Sendable {

    /// HealthKit never invoked the completion handler within the allotted time.
    /// Known Apple bug (Developer Forums #769355, unresolved) — the native async
    /// variant can suspend forever on ~5% of workouts.
    case timedOut(seconds: TimeInterval)

    /// HealthKit reported a send failure.
    case failed(underlying: (any Error)?)
}

/// Transition-based send-health logging (IOS-00100-E).
///
/// The 1 Hz tick sender used to log EVERY failed send with a full NSError dump —
/// a single 3-minute outage produced ~40 identical lines, and the 2026-07-09
/// session log was ~70% this noise. Only the EDGES carry information: the first
/// failure (link went down) and the first success after failures (link restored,
/// with how many sends the outage ate). Everything in between is a counter.
public actor MirroringSendHealth {

    public static let shared = MirroringSendHealth()

    private var consecutiveFailures = 0

    func recordFailure(_ error: any Error) async {
        consecutiveFailures += 1
        if consecutiveFailures == 1 {
            await WorkoutFileLogger.shared.log("[Send] link DOWN — first failure: \(error)")
        }
    }

    func recordSuccess() async {
        guard consecutiveFailures > 0 else { return }
        await WorkoutFileLogger.shared.log("[Send] link RESTORED — after \(consecutiveFailures) failed send(s)")
        consecutiveFailures = 0
    }
}

extension HKWorkoutSession {

    /// Sends data over the HealthKit mirroring channel guarded by a hard timeout.
    ///
    /// Apple's `sendToRemoteWorkoutSession(data:)` async variant can hang forever when
    /// HealthKit never calls its completion handler (Forums #769355). A structured race
    /// (`withThrowingTaskGroup`) cannot guard against it — the group awaits all children
    /// and the zombie child never resumes. This wrapper owns its continuation instead:
    /// it resumes on completion OR on timeout, whichever fires first; a late completion
    /// callback is ignored.
    ///
    /// Retries once after a timeout/failure by default. File logging is
    /// transition-based via `MirroringSendHealth` (IOS-00100-E) — link DOWN /
    /// RESTORED edges instead of one NSError dump per beat.
    public func sendToRemoteWorkoutSession(
        data: Data,
        timeout seconds: TimeInterval,
        retries: Int = 1
    ) async throws {
        var attempt = 1
        while true {
            do {
                try await sendOnce(data: data, timeout: seconds)
                await MirroringSendHealth.shared.recordSuccess()
                return
            } catch {
                guard attempt <= retries else {
                    await MirroringSendHealth.shared.recordFailure(error)
                    throw error
                }
                attempt += 1
            }
        }
    }

    private func sendOnce(data: Data, timeout seconds: TimeInterval) async throws {
        let hasResumed = OSAllocatedUnfairLock(initialState: false)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            @Sendable func resumeOnce(_ result: Result<Void, any Error>) {
                let shouldResume = hasResumed.withLock { resumed in
                    if resumed { return false }
                    resumed = true
                    return true
                }
                if shouldResume {
                    continuation.resume(with: result)
                }
            }

            let timeoutTask = Task {
                try? await Task.sleep(for: .seconds(seconds))
                resumeOnce(.failure(MirroringSendError.timedOut(seconds: seconds)))
            }

            sendToRemoteWorkoutSession(data: data) { success, error in
                resumeOnce(success ? .success(()) : .failure(MirroringSendError.failed(underlying: error)))
                // Without cancel, every fast send left a 3-second zombie Task behind
                // (1 tick/s = ~3 dangling tasks throughout the workout — pure waste).
                timeoutTask.cancel()
            }
        }
    }
}

#endif
