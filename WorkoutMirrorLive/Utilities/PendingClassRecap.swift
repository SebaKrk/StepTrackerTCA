//
//  PendingClassRecap.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import ComposableArchitecture
import Foundation

/// Class recap received from the iPad at class end, waiting until the participant's
/// `HKWorkout` is saved so it can be linked to the workout as a `ClassParticipation`
/// (IOS-00104-C). Mirrors `PendingEffortScore`: the same park-then-consume pattern,
/// consumed at the same `.workoutSaved` / `savedWorkoutFound` hook.
///
/// Composed on the participant from the BLE `ClassRecapPayload` (place, count,
/// coordinates, classSessionId) plus locally-known values: `gymName` from the scanned
/// QR and `classPoints` from the on-device window-scoped counter (IOS-00104-B).
///
/// `nonisolated` — under the project's `defaultIsolation(MainActor.self)` the
/// synthesized `Codable` would be main-actor-isolated, which cannot satisfy the
/// `Sendable` requirement of `FileStorageKey`.
nonisolated struct PendingClassRecap: Codable, Equatable, Sendable {

    /// Class-session instance (links to `ClassSessionRecord.id`).
    let classSessionId: UUID

    /// Class display name (from the scanned QR).
    let gymName: String

    /// Finishing place in the class ranking (1-based).
    let place: Int

    /// Total number of participants.
    let participantCount: Int

    /// Points earned in the class window (from the on-device window counter).
    let classPoints: Int

    /// Class location coordinates for the recap map — `nil` when no geocoded address.
    let latitude: Double?
    let longitude: Double?

    /// When the recap was received — drives the staleness guard on consume (a recap
    /// from an abandoned session must not attach to an unrelated workout saved later).
    let captureDatetime: Date
}

extension SharedKey where Self == FileStorageKey<PendingClassRecap?>.Default {

    /// `.fileStorage` (not `.appStorage`) — the value must survive an app kill:
    /// `.workoutSaved` can arrive on the next launch (guaranteed `transferUserInfo`).
    static var pendingClassRecap: Self {
        Self[
            .fileStorage(.documentsDirectory.appending(component: "pending-class-recap.json")),
            default: nil
        ]
    }
}
