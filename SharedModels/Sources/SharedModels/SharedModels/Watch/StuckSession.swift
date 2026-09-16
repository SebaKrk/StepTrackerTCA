//
//  StuckSession.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/05/2026.
//

import Foundation

/// Snapshot of an active `HKWorkoutSession` recovered on Watch app launch.
///
/// Returned by `WatchWorkoutSessionClient.recoverStuckSession()` when the previous
/// app run left a workout session unfinished (e.g. crash, battery death, force-quit).
/// The session is auto-finalized at that point — this snapshot only feeds logging.
///
/// `activityTypeRaw` is kept as `UInt` to avoid importing `HealthKit` in `SharedModels`
/// — callers reconstruct `HKWorkoutActivityType(rawValue:)` on the Watch side.
///
/// - SeeAlso: `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+).
public struct StuckSession: Sendable, Equatable {

    /// Raw value of the recovered session's `HKWorkoutActivityType`.
    public let activityTypeRaw: UInt

    /// Moment when the recovered session was originally started, per `HKWorkoutSession.startDate`.
    public let startDate: Date

    public init(activityTypeRaw: UInt, startDate: Date) {
        self.activityTypeRaw = activityTypeRaw
        self.startDate = startDate
    }
}
