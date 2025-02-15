//
//  WeightLiftingExercise.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// An enumeration representing different types of weightlifting movements.
///
/// This enum includes Olympic lifts and their variations, providing a structured way
/// to categorize exercises and use them within the app.
enum WeightliftingMovement: String, Codable, CaseIterable {
    
    /// The Clean & Jerk movement, a two-part Olympic lift.
    case cleanAndJerk
    
    /// The Snatch movement, an Olympic lift performed in one motion.
    case snatch
    
    /// The Overhead Squat, a squat performed with the barbell overhead.
    case overheadSquat
    
    /// The Power Clean, a variation of the Clean where the lifter catches the bar in a higher position.
    case powerClean
    
    /// The Squat Clean, another name for the full Clean, where the lifter catches the bar in a deep squat.
    case squatClean
    
    /// The Split Jerk, a variation of the Jerk where the feet split apart during the catch phase.
    case splitJerk

    /// A user-friendly title for each movement.
    ///
    /// This computed property returns a properly formatted string representation
    /// of the movement's name for UI display.
    var title: String {
        switch self {
        case .cleanAndJerk:
            return "Clean & Jerk"
        case .snatch:
            return "Snatch"
        case .overheadSquat:
            return "Overhead Squat"
        case .powerClean:
            return "Power Clean"
        case .squatClean:
            return "Squat Clean"
        case .splitJerk:
            return "Split Jerk"
        }
    }

    /// A description of the movement.
    ///
    /// This property is currently empty but can be expanded to include
    /// detailed explanations or training tips for each movement.
    var description: String {
        switch self {
        case .cleanAndJerk,
             .snatch,
             .overheadSquat,
             .powerClean,
             .squatClean,
             .splitJerk:
            return ""
        }
    }
}
