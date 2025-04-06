//
//  Movement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/03/2025.
//

import Foundation

/// An enumeration representing different categories of workouts, where each case
/// corresponds to a specific type of movement. This enum provides a unified way to
/// handle various workout types with associated details.
///
/// Cases:
/// - `cross`: Represents movements related to CrossFit workouts.
/// - `fitness`: Represents general fitness-related movements.
/// - `strength`: Represents strength training movements.
/// - `hero`: Represents special Hero workouts, typically named workouts.
/// - `weightlifting`: Represents Olympic weightlifting movements.
///
/// Properties:
/// - `title`: A human-readable title of the movement, obtained from the associated type.
/// - `description`: A detailed description of the movement, obtained from the associated type.
enum Movement {
    case cross(CrossMovement)
    case fitness(FitnessMovement)
    case strength(StrengthMovement)
    case hero(HeroMovement)
    case weightlifting(WeightliftingMovement)
    
    var title: String {
        switch self {
        case .cross(let movement):
            return movement.title
        case .fitness(let movement):
            return movement.title
        case .strength(let movement):
            return movement.title
        case .hero(let movement):
            return movement.title
        case .weightlifting(let movement):
            return movement.title
        }
    }
    
    var description: String {
        switch self {
        case .cross(let movement):
            return movement.description
        case .fitness(let movement):
            return movement.description
        case .strength(let movement):
            return movement.description
        case .hero(let movement):
            return movement.description
        case .weightlifting(let movement):
            return movement.description
        }
    }
    
}
