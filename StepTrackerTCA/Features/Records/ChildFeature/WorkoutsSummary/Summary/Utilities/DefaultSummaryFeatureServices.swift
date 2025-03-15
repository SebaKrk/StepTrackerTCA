//
//  DefaultSummaryFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Factory
import Foundation

final class DefaultSummaryFeatureServices: SummaryFeatureServices {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.workoutStrengthRepository) private var workoutStrengthRepository
    @LazyInjected(\.weightLiftingRepository) private var weightLiftingRepository
    
    // MARK: - API
    
    /// Fetches and returns a workout summary containing all recorded workout sessions.
    func fetchWorkoutSummary() async throws -> WorkoutSummary {
        let sessions = try await [
            workoutStrengthRepository.fetchSessions(),
            weightLiftingRepository.fetchSessions()
        ].flatMap { $0 }
        
        return WorkoutSummary(workouts: sessions)
    }
    
    /// Groups workout sessions by their workout type.
    func groupWorkoutsByWorkoutType(_ summary: WorkoutSummary) -> [NewGroupedWorkouts] {
        let groupedByType = groupSessionsByWorkoutType(summary)
        
        return groupedByType.map { (workoutType, sessions) in
            let groupedMovements = groupMovementsBySession(sessions)
            return NewGroupedWorkouts(workoutType: workoutType, movements: groupedMovements)
        }
    }
    
    // MARK: - Private methods
    
    /// Groups workout sessions by their workout type.
    ///
    /// - Parameter summary: A `WorkoutSummary` containing workout sessions.
    /// - Returns: A dictionary where the key is `WorkoutType` and the value is an array of workout sessions.
    private func groupSessionsByWorkoutType(_ summary: WorkoutSummary) -> [WorkoutType: [any WorkoutSessionProtocol]] {
        summary.workouts
            .reduce(into: [WorkoutType: [any WorkoutSessionProtocol]]()) { result, session in
                result[session.workoutType, default: []].append(session)
            }
    }
    
    /// Groups movements by their session.
    ///
    /// - Parameter sessions: An array of workout sessions.
    /// - Returns: An array of `NewGroupedMovement`, where movements are grouped by their title.
    private func groupMovementsBySession(_ sessions: [any WorkoutSessionProtocol]) -> [NewGroupedMovement] {
        let groupedMovements = sessions
            .reduce(into: [String: [any WorkoutSessionProtocol]]()) { result, session in
                let movementKey = session.movement.title
                result[movementKey, default: []].append(session)
            }
            .map { NewGroupedMovement(movement: $0.value.first!.movement, sessions: $0.value) }

        return groupedMovements
    }
    
}
