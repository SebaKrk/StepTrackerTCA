//
//  WorkoutType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different types of workout categories.
///
/// This enum categorizes workouts into five major groups: Weightlifting, Strength,
/// Fitness, Cross Training, and Hero Workouts. Each type serves a unique purpose
/// in training and performance tracking.
///
/// - `weightlifting`: Olympic and powerlifting movements that require skill and technique.
/// - `strength`: Fundamental strength-building exercises with progressive overload.
/// - `fitness`: Cardiovascular and endurance-based activities.
/// - `cross`: Functional fitness workouts emphasizing intensity and variety.
/// - `hero`: Special benchmark workouts, often named after military personnel.
enum WorkoutType: String, Codable, CaseIterable {
    
    /// Weightlifting - Focuses on Olympic-style lifts and variations.
    case weightlifting
    
    /// Strength - Includes fundamental strength movements like squats, presses, and deadlifts.
    case strength
    
    /// Fitness - Covers endurance-based activities like running, swimming, and rowing.
    case fitness
    
    /// Cross Training - High-intensity functional fitness workouts.
    case cross
    
    /// Hero Workouts - Special named workouts often used as benchmarks.
    case hero
    
    /// A user-friendly title for each workout type.
    ///
    /// Used for display purposes in UI components.
    var title: String {
        switch self {
        case .weightlifting:
            return "Weightlifting"
        case .strength:
            return "Strength"
        case .fitness:
            return "Fitness"
        case .cross:
            return "Cross"
        case .hero:
            return "Hero Workouts"
        }
    }
    
    /// A detailed description of each workout type.
    ///
    /// Provides an explanation of the purpose and focus of each workout category.
    var description: String {
        switch self {
        case .weightlifting:
            return "Olympic-style lifts and power movements focusing on explosive strength and technique."
        case .strength:
            return "Core strength exercises such as squats, deadlifts, and bench presses aimed at muscle growth and power."
        case .fitness:
            return "Endurance-based activities including running, cycling, rowing, and swimming to improve cardiovascular health."
        case .cross:
            return "High-intensity workouts combining strength, cardio, and bodyweight exercises for functional fitness."
        case .hero:
            return "Benchmark workouts named after fallen heroes, testing overall fitness, endurance, and resilience."
        }
    }
    
}
