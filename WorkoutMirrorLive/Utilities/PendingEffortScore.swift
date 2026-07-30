//
//  PendingEffortScore.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/07/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Effort points snapshot taken when a workout ends, waiting for the Watch to
/// report the saved workout UUID (`.workoutSaved`) so the frozen score can be
/// written against its `HKWorkout` (IOS-00099-F5).
///
/// The points are computed live on-device during the workout (the same
/// accumulator shown on screen and sent to GymRoom); this captures its final
/// value at teardown. "A result is a result" — never recomputed from HealthKit,
/// never recalculated on a weights change.
///
/// Written by `SessionFeature` on session end; consumed (and cleared) by the
/// app-level listener in `AppTabNewFeature` when the UUID arrives.
///
/// `nonisolated` — under the project's `defaultIsolation(MainActor.self)` the
/// synthesized `Codable` conformance would be main-actor-isolated, which cannot
/// satisfy the `Sendable` requirement of `FileStorageKey`.
nonisolated struct PendingEffortScore: Codable, Equatable, Sendable {

    /// Final effort points at workout end.
    let points: Int

    /// Seconds accumulated per training zone — persisted for future stats and
    /// to keep the record self-describing (which zones produced the points).
    let secondsByZone: [HeartRateZone: TimeInterval]

    /// Workout start timestamp — the record's date, drives monthly aggregates
    /// and the staleness guard on consume.
    let workoutStartDate: Date

    /// Weights table version used for `points` (frozen — see `EffortPointsScoring`).
    let weightsVersion: Int
}

extension SharedKey where Self == FileStorageKey<PendingEffortScore?>.Default {

    /// `.fileStorage` (not `.appStorage`) — the value must survive an app kill:
    /// `transferUserInfo` can deliver `.workoutSaved` on the next launch.
    static var pendingEffortScore: Self {
        Self[
            .fileStorage(.documentsDirectory.appending(component: "pending-effort-score.json")),
            default: nil
        ]
    }
}
