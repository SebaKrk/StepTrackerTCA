//
//  WorkoutParsingClient+Strategies.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import SharedModels
import Foundation

extension WorkoutParsingClient {

    // MARK: - Foundation Models Strategy

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    public static let foundationModels: WorkoutParsingClient = {
        let strategy = FoundationModelsStrategy()

        return WorkoutParsingClient(
            parseWorkout: { text in
                try await strategy.parseWorkoutText(text)
            }
        )
    }()
    #endif

    // MARK: - Claude API Strategy

    public static let claude: WorkoutParsingClient = {
        let strategy = ClaudeStrategy()

        return WorkoutParsingClient(
            parseWorkout: { text in
                try await strategy.parseWorkoutText(text)
            }
        )
    }()

    // MARK: - Mock Strategy

    public static let mock: WorkoutParsingClient = {
        WorkoutParsingClient(
            parseWorkout: { text in
                // Mock successful parse
                ExtractedWorkout(
                    name: "Mock Workout",
                    date: "2026-02-12",
                    totalEstimatedMinutes: 60,
                    sections: []
                )
            }
        )
    }()
}
