//
//  WorkoutTypeOption.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import Foundation

enum WorkoutTypeOption: ButtonActionOption {
    
    case customWorkout
    case singleGoalWorkout
    case pacerWorkout

    var name: String {
        switch self {
        case .customWorkout:
            return "Custom"
        case .singleGoalWorkout:
            return "Single"
        case .pacerWorkout:
            return "Pacer"
        }
    }

    var icon: String {
        switch self {
        case .customWorkout:
            return "figure.cross.training"
        case .singleGoalWorkout:
            return "figure.strengthtraining.functional"
        case .pacerWorkout:
            return "figure.run"
        }
    }

    var actionDescription: String {
        switch self {
        case .customWorkout:
            return "Create a custom workout."
        case .singleGoalWorkout:
            return "Create single goal workouts."
        case .pacerWorkout:
            return "Create workout with distance and time goals"
        }
    }
    
}
