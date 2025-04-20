//
//  StrengthMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different types of strength movements.
///
/// Strength movements focus on building muscular power and endurance, often performed
/// with free weights, barbells, or bodyweight resistance.
enum StrengthMovement: String, Codable, MovementType {
    
    /// The Back Squat movement, a key lower-body strength exercise.
    case backSquat = "BackSquat"
    
    /// The Deadlift, a compound movement that targets posterior chain muscles.
    case deadlift = "Deadlift"
    
    /// The Front Squat, a squat variation with the barbell positioned in front of the shoulders.
    case frontSquat = "FrontSquat"
    
    /// The Weighted Pull-Ups, an upper-body strength movement with additional resistance.
    case weightedPullUps = "WeightedPullUps"
    
    /// The Push Press, a dynamic upper-body strength movement that includes leg drive.
    case pushPress = "PushPress"
    
    /// The Bench Press, a key upper-body pushing exercise.
    case benchPress = "BenchPress"

    /// A user-friendly title for each movement.
    ///
    /// This computed property returns a properly formatted string representation
    /// of the movement's name for UI display.
    var title: String {
        switch self {
        case .backSquat:
            return "Back Squat"
        case .deadlift:
            return "Deadlift"
        case .frontSquat:
            return "Front Squat"
        case .weightedPullUps:
            return "Weighted Pull-Ups"
        case .pushPress:
            return "Push Press"
        case .benchPress:
            return "Bench Press"
        }
    }

    /// A description of the movement.
    ///
    /// This property provides a brief explanation of each exercise.
    var description: String {
        switch self {
        case .backSquat:
            return "A fundamental lower-body exercise that builds strength and stability."
        case .deadlift:
            return "A powerful full-body exercise that primarily targets the posterior chain."
        case .frontSquat:
            return "A squat variation that shifts emphasis to the quadriceps and core."
        case .weightedPullUps:
            return "An advanced upper-body exercise that increases pulling strength by adding resistance."
        case .pushPress:
            return "A compound exercise that develops explosive strength in the shoulders and arms."
        case .benchPress:
            return "A key upper-body pushing exercise that primarily targets the chest, shoulders, and triceps."
        }
    }
    
    /// A system symbol representing the strength movement.
    ///
    /// This computed property returns an appropriate SF Symbol for each strength movement,
    /// providing a visual representation for improved user experience.
    var icon: String {
        switch self {
        case .backSquat:
            return "figure.squat"
        case .deadlift:
            return "figure.strength"
        case .frontSquat:
            return "figure.front.squat"
        case .weightedPullUps:
            return "figure.pullup"
        case .pushPress:
            return "figure.press"
        case .benchPress:
            return "figure.bench.press"
        }
    }
    
    static func from(rawValue: String) -> StrengthMovement? {
        return StrengthMovement.allCases.first { $0.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame }
    }
}
