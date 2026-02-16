//
//  WorkoutParsingStrategy.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation
import SharedModels

/// Protocol defining a strategy for parsing OCR text into structured workouts.
///
/// Conforming types implement different parsing backends:
/// - ``FoundationModelsStrategy``: On-device parsing using Apple Intelligence (iOS 26+)
/// - ``ClaudeAPIStrategy``: Cloud-based parsing using Claude API
///
/// The strategy pattern allows runtime selection based on device capabilities
/// and user preferences, while keeping the feature layer decoupled from
/// implementation details.
public protocol WorkoutParsingStrategy: Sendable {

    /// Parses raw OCR text into a structured workout.
    ///
    /// - Parameter text: Raw text recognized by Vision OCR from a workout photo.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: Strategy-specific errors (e.g., network failures, model unavailability).
    func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout
}
