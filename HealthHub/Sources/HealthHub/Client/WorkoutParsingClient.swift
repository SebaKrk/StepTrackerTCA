//
//  WorkoutParsingClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Dependencies
import Foundation
import SharedModels

/// TCA dependency client for workout parsing.
///
/// Provides access to different parsing strategies (Foundation Models vs Claude API).
/// Strategy selection is **manual** - developer chooses in `liveValue`.
public struct WorkoutParsingClient: Sendable {

    /// Parses OCR text into structured workout.
    ///
    /// Implementation depends on selected strategy (FM or Claude).
    public var parseWorkout: @Sendable (_ text: String) async throws -> ExtractedWorkout
}

// MARK: - Dependency

extension WorkoutParsingClient: DependencyKey {

    // ============================================
    // 🎛️ MANUAL STRATEGY SELECTION
    // ============================================
    public static let liveValue: WorkoutParsingClient = .claude

    // Zmień na .foundationModels gdy Apple poprawi FM:
    // public static let liveValue: WorkoutParsingClient = .foundationModels

    public static let testValue: WorkoutParsingClient = {
        WorkoutParsingClient(
            parseWorkout: unimplemented("WorkoutParsingClient.parseWorkout")
        )
    }()
}

extension DependencyValues {
    public var workoutParsingClient: WorkoutParsingClient {
        get { self[WorkoutParsingClient.self] }
        set { self[WorkoutParsingClient.self] = newValue }
    }
}
