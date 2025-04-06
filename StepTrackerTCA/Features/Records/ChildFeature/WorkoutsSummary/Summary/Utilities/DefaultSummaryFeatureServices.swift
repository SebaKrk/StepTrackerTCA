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
    @LazyInjected(\.workoutFitnessRepository) private var workoutFitnessRepository
    @LazyInjected(\.workoutCrossRepository) private var workoutCrossRepository
    
    @LazyInjected(\.goalsRepository) private var goalsRepository
    
    // MARK: - API
    
    /// Retrieves a workout summary.
    func fetchWorkoutSummary() async throws -> Summary {
        let strength: [WorkoutStrength] = try await workoutStrengthRepository.fetchWorkoutStrengthSummary()
        let weightLifting: [WorkoutWeightlifting] = try await weightLiftingRepository.fetchWeightLiftingStats()
        let fitness: [WorkoutFitness] = try await workoutFitnessRepository.fetchWorkoutFitnessSummary()
        let cross: [WorkoutCross] = try await workoutCrossRepository.fetchWorkoutCrossSummary()
        
        let goals: [WorkoutGoal] = try await goalsRepository.fetchAllGoals()

        let strengthMeasurements = strength.map { mapToMeasurement($0, type: .strength) }
        let weightLiftingMeasurements = weightLifting.map { mapToMeasurement($0, type: .weightlifting) }
        let fitnessMeasurements = fitness.map { mapToMeasurement($0, type: .fitness) }
        let crossMeasurements = cross.map { mapToMeasurement($0, type: .cross) }
        
        let allMeasurements = strengthMeasurements + weightLiftingMeasurements + fitnessMeasurements + crossMeasurements

        return Summary(measurements: allMeasurements, goals: goals)
    }
    
    /// Groups the given workout summary data into categorized movements.
    func groupSummaryData(_ summary: Summary) -> [GroupedMovement] {
        return WorkoutType.allCases.compactMap { type -> GroupedMovement? in
            let filteredMeasurements = summary.measurements.filter { $0.workoutType == type }
            guard !filteredMeasurements.isEmpty else { return nil }
            let filteredGoals = summary.goals.filter { $0.workoutType == type.rawValue }
            return GroupedMovement(
                workoutType: type,
                movements: filteredMeasurements,
                goals: filteredGoals
            )
        }
    }
    
    /// Processes the grouped movements to group them by movement, preserving all measurements.
    func processGroupedMovements(_ grouped: [GroupedMovement]) -> [GroupedMovement] {
        return grouped.map { group in
            let groupedMovements = groupByMovement(from: group)
            return GroupedMovement(
                workoutType: group.workoutType,
                movements: groupedMovements,
                goals: group.goals
            )
        }
    }
    
    func groupByMovement(from data: GroupedMovement) -> [WorkoutMeasurement] {
        var latestMovements: [WorkoutMeasurement] = []

        data.movements.forEach { measurement in
            if let index = latestMovements.firstIndex(where: { $0.movement == measurement.movement }) {
                if measurement.date > latestMovements[index].date {
                    latestMovements[index] = measurement
                }
            } else {
                latestMovements.append(measurement)
            }
        }
        
        return latestMovements
    }
    
    private func mapToMeasurement<T: WorkoutSession>(_ item: T, type: WorkoutType) -> WorkoutMeasurement {
        WorkoutMeasurement(
            id: item.id,
            workoutType: type,
            movement: item.movement,
            date: item.date,
            value: Double(item.value) ?? 0
        )
    }
    
}
