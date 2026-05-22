//
//  StuckSession.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/05/2026.
//

import Foundation

/// Snapshot of an active `HKWorkoutSession` recovered on Watch app launch.
///
/// Returned by `WatchWorkoutSessionClient.checkForStuckSession()` when the previous
/// app run left a workout session unfinished (e.g. iPhone died mid-workout, Watch app
/// was force-quit). The recovery alert presents this context to the user before they
/// decide whether to finalize the workout or discard it.
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
