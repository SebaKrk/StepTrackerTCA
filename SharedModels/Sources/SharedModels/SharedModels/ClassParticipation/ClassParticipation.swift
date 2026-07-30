//
//  ClassParticipation.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import Foundation

/// A participant's record of attending a GymRoom class, linked 1:1 to their workout
/// (`hkWorkoutId`). Frozen at class end from the recap the iPad broadcasts (place,
/// participant count, coordinates) combined with what the participant knew locally
/// (`gymName` from the scanned QR, `classPoints` from the window-scoped counter,
/// IOS-00104-B). Powers the "class recap" section in the workout's Activity Details.
///
/// Separate from `WorkoutEffortScore` on purpose: effort score only exists when the
/// workout earned points (> 0), but attendance should show even for a zero-point class.
public struct ClassParticipation: Identifiable, Equatable, Codable, Sendable {

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public let id: UUID

    /// Reference to HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public let hkWorkoutId: UUID

    /// The class-session instance attended (links to `ClassSessionRecord.id`).
    public let classSessionId: UUID

    /// Class display name (from the scanned QR `gymName`).
    public let gymName: String

    /// Finishing place in the class ranking (1-based).
    public let place: Int

    /// Total number of participants in the class.
    public let participantCount: Int

    /// Points earned within the class window (window-scoped, IOS-00104-B).
    public let classPoints: Int

    /// Class location coordinates for the recap map — `nil` when the class had no
    /// geocoded address.
    public let latitude: Double?
    public let longitude: Double?

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        classSessionId: UUID,
        gymName: String,
        place: Int,
        participantCount: Int,
        classPoints: Int,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.classSessionId = classSessionId
        self.gymName = gymName
        self.place = place
        self.participantCount = participantCount
        self.classPoints = classPoints
        self.latitude = latitude
        self.longitude = longitude
    }
}
