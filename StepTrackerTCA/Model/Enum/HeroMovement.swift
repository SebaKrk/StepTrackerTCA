//
//  HeroMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different Hero benchmark workouts.
///
/// Hero WODs are named in honor of fallen heroes and are known for their high intensity,
/// long duration, and challenging nature. They often include a combination of weightlifting,
/// gymnastics, and endurance exercises performed against the clock.
enum HeroMovement: String, Codable, MovementType {
    
    /// Chad 1000x - 1000 box step-ups for time.
    case chad1000x
    
    /// Fran - 21-15-9 reps of thrusters and pull-ups for time.
    case fran
    
    /// Helen - 3 rounds of a 400m run, kettlebell swings, and pull-ups for time.
    case helen
    
    /// Murphy - 1-mile run, 100 pull-ups, 200 push-ups, 300 squats, 1-mile run for time.
    case murphy
    
    /// Grace - 30 clean and jerks for time.
    case grace

    /// A user-friendly title for each Hero workout.
    ///
    /// This computed property returns a properly formatted string representation
    /// of the workout's name for UI display.
    var title: String {
        switch self {
        case .chad1000x:
            return "Chad 1000x"
        case .fran:
            return "Fran"
        case .helen:
            return "Helen"
        case .murphy:
            return "Murphy"
        case .grace:
            return "Grace"
        }
    }

    /// A description of the workout.
    ///
    /// Each Hero WOD is performed for time, testing overall fitness, endurance, and resilience.
    var description: String {
        switch self {
        case .chad1000x:
            return "Complete 1,000 box step-ups for time. A true test of endurance and mental toughness."
        case .fran:
            return "Perform 21-15-9 reps of thrusters and pull-ups as fast as possible."
        case .helen:
            return "Complete 3 rounds of a 400m run, 21 kettlebell swings, and 12 pull-ups for time."
        case .murphy:
            return "Perform a 1-mile run, 100 pull-ups, 200 push-ups, 300 air squats, and another 1-mile run for time."
        case .grace:
            return "Complete 30 clean and jerks for time. This workout tests strength, power, and efficiency."
        }
    }
}
