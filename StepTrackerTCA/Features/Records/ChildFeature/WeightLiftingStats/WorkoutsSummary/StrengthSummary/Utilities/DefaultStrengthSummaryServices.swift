//
//  DefaultStrengthSummaryServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Factory
import Foundation

final class DefaultStrengthSummaryServices: StrengthSummaryServices {
    
    
    // MARK: - Dependencies
    
    @LazyInjected(\.workoutStrengthRepository) private var workoutStrengthRepository
    
    // MARK: - API
    
    func fetchWorkoutStrengthSummary() async throws -> [WorkoutStrength]? {
        try await workoutStrengthRepository.fetchWorkoutStrengthSummary()
    }
    
    func mapToMovementSummaries<T: MovementType>(_ goal: Double?, data: [WorkoutStrength]) -> [MovementSummary<T>] {
        let groupedWorkouts = groupWorkoutsByMovement(data)
        return groupedWorkouts.compactMap { createMovementSummary(from: $0, goal: goal) }
    }

    // MARK: - Private methods
    
    private func groupWorkoutsByMovement(_ data: [WorkoutStrength]) -> [String: [WorkoutStrength]] {
        let grouped = Dictionary(grouping: data, by: { $0.movement.rawValue })
        return sortGroupedWorkouts(grouped)
    }

    private func sortGroupedWorkouts(_ groupedWorkouts: [String: [WorkoutStrength]]) -> [String: [WorkoutStrength]] {
        return groupedWorkouts.mapValues { $0.sorted(by: { $0.movement.rawValue < $1.movement.rawValue }) }
    }

    private func findBestWorkout(from workouts: [WorkoutStrength]) -> WorkoutStrength? {
        return workouts.max(by: { Double($0.value) ?? 0.0 < Double($1.value) ?? 0.0 })
    }
    
    private func createMovementSummary<T: MovementType>(from entry: (key: String, value: [WorkoutStrength]), goal: Double?) -> MovementSummary<T>? {
        guard let bestWorkout = findBestWorkout(from: entry.value) else { return nil }

        return MovementSummary(
            id: bestWorkout.id,
            movement: bestWorkout.movement as! T,
            goal: goal,
            latestResult: Double(bestWorkout.value) ?? 0.0
        )
    }
    
}

