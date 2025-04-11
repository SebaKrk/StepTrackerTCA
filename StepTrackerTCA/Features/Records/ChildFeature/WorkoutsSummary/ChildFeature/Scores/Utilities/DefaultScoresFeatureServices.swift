//
//  DefaultScoresFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Factory
import Foundation

/// A default implementation of `ScoresFeatureServices` that provides functionality for evaluating workout sessions.
final class DefaultScoresFeatureServices: ScoresFeatureServices {
    
    // MARK: - Properties
    
    private let strategy: (WorkoutType) -> WorkoutSummaryStrategy
    
    // MARK: - Lifecycle

    init(strategy: @escaping (WorkoutType) -> WorkoutSummaryStrategy) {
        self.strategy = strategy
    }
    
    // MARK: - API
    
    /// This function retrieves workout measurements and associated goals for the given workout type.
    func fetchSummary(for workoutType: WorkoutType) async throws -> Summary {
        let strategy = strategy(workoutType)
        return try await strategy.fetchSummary()
    }
    
    /// Maps the provided summary data into a grouped movement structure.
    func mapToGroupedMovement(from summary: Summary, workoutType: WorkoutType) -> GroupedMovement {
        return GroupedMovement(
            workoutType: workoutType,
            movements: summary.measurements,
            goals: summary.goals.isEmpty ? nil : summary.goals
        )
    }
    
    /// Returns the best workout session from the given list of sessions.
    func bestSession(from sessions: [any WorkoutSession]) -> (any WorkoutSession)? {
        return sessions.max { Double($0.value) ?? 0 < Double($1.value) ?? 0 }
    }

    /// Filters movements from the provided summary based on predefined criteria.
    func filterMovements(from summary: Summary) -> [ScoresFeature.FilteredMovement] {
        let groupedMeasurements = Dictionary(grouping: summary.measurements, by: { $0.movement })
        
        return groupedMeasurements.compactMap { movement, measurements in
            let best = measurements.max(by: { $0.value < $1.value })
            let last = measurements.max(by: { $0.date < $1.date })
            let goal = summary.goals.filter { $0.movement == movement }.last
            
            return ScoresFeature.FilteredMovement(
                id: movement,
                movement: movement,
                best: best,
                last: last,
                goal: goal
            )
        }
    }
    
    // MARK: - Private methods
    
    /// Maps a generic workout session to a standardized `WorkoutMeasurement`.
    ///
    /// This function converts a `WorkoutSession` instance to a `WorkoutMeasurement`
    /// using the provided workout type.
    /// - Parameters:
    ///   - item: The workout session to be mapped.
    ///   - type: The workout type related to the session.
    /// - Returns: A `WorkoutMeasurement` object representing the converted workout session.
    private func mapToMeasurement<T: WorkoutSession>(_ item: T, type: WorkoutType) -> WorkoutMeasurement {
        return WorkoutMeasurement(
            id: item.id,
            workoutType: type,
            movement: item.movement,
            date: item.date,
            value: Double(item.value) ?? 0.0
        )
    }
    
}
