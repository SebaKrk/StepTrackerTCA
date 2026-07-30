//
//  PendingPlanLink.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 03/07/2026.
//

import ComposableArchitecture
import Foundation

/// Pending "workout started from a plan" context, waiting for the Watch to report
/// the saved workout UUID (`.workoutSaved`) so the plan and the `HKWorkout` can be
/// linked in the database (IOS-00098-C).
///
/// Written by `SessionFeature` when a plan-based workout starts; consumed (and cleared)
/// by the app-level listener in `AppTabNewFeature` when the UUID arrives.
///
/// `nonisolated` — under the project's `defaultIsolation(MainActor.self)` the synthesized
/// `Codable` conformance would be main-actor-isolated, which cannot satisfy the `Sendable`
/// requirement of `FileStorageKey`.
nonisolated struct PendingPlanLink: Codable, Equatable, Sendable {

    /// Source `TrainingSession` plan the workout was started from.
    let trainingSessionId: UUID

    /// Workout start timestamp — becomes the execution date of the score record
    /// and drives the staleness guard on consume.
    let workoutStartDate: Date
}

extension SharedKey where Self == FileStorageKey<PendingPlanLink?>.Default {

    /// `.fileStorage` (not `.appStorage`) — the value must survive an app kill:
    /// `transferUserInfo` can deliver `.workoutSaved` on the next launch.
    static var pendingPlanLink: Self {
        Self[
            .fileStorage(.documentsDirectory.appending(component: "pending-plan-link.json")),
            default: nil
        ]
    }
}
