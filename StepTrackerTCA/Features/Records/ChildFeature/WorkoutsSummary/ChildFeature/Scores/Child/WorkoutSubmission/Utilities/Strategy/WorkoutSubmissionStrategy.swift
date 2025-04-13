//
//  WorkoutSubmissionStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

// strategy
protocol WorkoutSubmissionStrategy {
    func submit(
        workout: WorkoutType,
        movement: String,
        date: Date,
        value: String,
        unit: String
    ) async throws
}

// Strategy - Submit
struct SubmitWorkoutStrategy: WorkoutSubmissionStrategy {
    
    let service: SubmitWorkoutService
    
    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.submitWorkout(for: workout, movement, date: date, value: value, unit: unit)
    }
}

// Strategy add Goal
struct SetGoalStrategy: WorkoutSubmissionStrategy {
    
    let service: SetEditGoalService

    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.setNewGoal(for: workout, movement, date: date, value: value, unit: unit)
    }
}


// Factory
enum Service {
    case submit 
    case setGoal
}

protocol WorkoutSubmissionStrategyFactory {
    func strategy(for service: Service) -> WorkoutSubmissionStrategy
}

struct DefaultWorkoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
    func strategy(for service: Service) -> WorkoutSubmissionStrategy {
        switch service {
        case .setGoal:
            return SetGoalStrategy(service: DefaultSetEditGoalService())
        case .submit:
            return SubmitWorkoutStrategy(service: DefaultSubmitWorkoutService())
        }
    }
}

