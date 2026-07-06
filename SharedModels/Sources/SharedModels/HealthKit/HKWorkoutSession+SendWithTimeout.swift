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
    /// Retries once after a timeout/failure by default. Callers keep their existing
    /// `catch` logging — this method only logs retry attempts to `WorkoutFileLogger`.
    public func sendToRemoteWorkoutSession(
        data: Data,
        timeout seconds: TimeInterval,
        retries: Int = 1
    ) async throws {
        var attempt = 0
        while true {
            do {
                try await sendOnce(data: data, timeout: seconds)
                return
            } catch {
                guard attempt < retries else { throw error }
                attempt += 1
                await WorkoutFileLogger.shared.log(
                    "[Send] attempt \(attempt) failed (\(error)) — retrying"
                )
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
