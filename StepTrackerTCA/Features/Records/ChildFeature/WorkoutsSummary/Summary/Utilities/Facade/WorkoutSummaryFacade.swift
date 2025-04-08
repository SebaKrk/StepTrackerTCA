//
//  WorkoutSummaryFacade.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/04/2025.
//

import Factory

final class WorkoutSummaryFacade {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.workoutStrengthRepository) private var workoutStrengthRepository
    @LazyInjected(\.weightLiftingRepository) private var weightLiftingRepository
    @LazyInjected(\.workoutFitnessRepository) private var workoutFitnessRepository
    @LazyInjected(\.workoutCrossRepository) private var workoutCrossRepository
    @LazyInjected(\.workoutHeroWodRepository) private var workoutHeroWodRepository
    
    // MARK: - API

    /// Fetches all measurements and returns them as a flattened array of `WorkoutMeasurement`.
    func fetchAllMeasurements() async throws -> [WorkoutMeasurement] {
        let strength: [any WorkoutSession] = try await workoutStrengthRepository.fetchWorkoutStrengthSummary()
        let weightLifting: [any WorkoutSession] = try await weightLiftingRepository.fetchWeightLiftingStats()
        let fitness: [any WorkoutSession] = try await workoutFitnessRepository.fetchWorkoutFitnessSummary()
        let cross: [any WorkoutSession] = try await workoutCrossRepository.fetchWorkoutCrossSummary()
        let hero: [any WorkoutSession] = try await workoutHeroWodRepository.fetchWorkoutHeroWodSummary()
        
        let strengthMeasurements = mapToMeasurements(sessions: strength)
        let weightLiftingMeasurements = mapToMeasurements(sessions: weightLifting)
        let fitnessMeasurements = mapToMeasurements(sessions: fitness)
        let crossMeasurements = mapToMeasurements(sessions: cross)
        let heroMeasurements = mapToMeasurements(sessions: hero)
        
        let allMeasurements = strengthMeasurements + weightLiftingMeasurements + fitnessMeasurements + crossMeasurements + heroMeasurements
        
        return allMeasurements
    }
    
    // MARK: - Private Methods
    
    private func mapToMeasurements(sessions: [any WorkoutSession]) -> [WorkoutMeasurement] {
        return sessions.compactMap { session in
            if let workoutType = WorkoutType(rawValue: session.workoutType) {
                return WorkoutMeasurement(
                    id: session.id,
                    workoutType: workoutType,
                    movement: session.movement,
                    date: session.date,
                    value: Double(session.value) ?? 0
                )
            } else {
                /// Ignorujemy nieznany typ zamiast przypisywać .unknown
                /// usun jak zdecydujesz sie dododac unknown
                return nil
            }
        }
    }

}



//    private func mapToMeasurements(sessions: [any WorkoutSession]) -> [WorkoutMeasurement] {
//        return sessions.map { session in
//            WorkoutMeasurement(
//                id: session.id,
//                workoutType: WorkoutType(rawValue: session.workoutType) ?? .unknown,
//                movement: session.movement,
//                date: session.date,
//                value: Double(session.value) ?? 0
//            )
//        }
//    }


// splaszczyc do jeden ?
//func fetchAllMeasurements() async throws -> [WorkoutMeasurement] {
//    async let strength: [any WorkoutSession] = workoutStrengthRepository.fetchWorkoutStrengthSummary()
//    async let weightLifting: [any WorkoutSession] = weightLiftingRepository.fetchWeightLiftingStats()
//    async let fitness: [any WorkoutSession] = workoutFitnessRepository.fetchWorkoutFitnessSummary()
//    async let cross: [any WorkoutSession] = workoutCrossRepository.fetchWorkoutCrossSummary()
//    async let hero: [any WorkoutSession] = workoutHeroWodRepository.fetchWorkoutHeroWodSummary()
//    
//    let sessions = try await [strength, weightLifting, fitness, cross, hero].flatMap { $0 }
//    return mapToMeasurements(sessions: sessions)
//}
