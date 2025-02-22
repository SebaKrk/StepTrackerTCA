//
//  StrengthMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different types of strength movements.
///
/// This enum includes fundamental strength exercises, providing a structured way
/// to categorize them and use them within the app.
enum StrengthMovement: String, Codable, CaseIterable {
    
    /// The Back Squat movement, a key lower-body strength exercise.
    case backSquat
    
    /// The Deadlift, a compound movement that targets posterior chain muscles.
    case deadlift
    
    /// The Front Squat, a squat variation with the barbell positioned in front of the shoulders.
    case frontSquat
    
    /// The Weighted Pull-Ups, an upper-body strength movement with additional resistance.
    case weightedPullUps
    
    /// The Push Press, a dynamic upper-body strength movement that includes leg drive.
    case pushPress
    
    /// The Bench Press, a key upper-body pushing exercise.
    case benchPress

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
}
