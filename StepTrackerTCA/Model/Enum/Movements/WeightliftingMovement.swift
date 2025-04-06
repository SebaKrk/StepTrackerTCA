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
enum WeightliftingMovement: String, Codable, MovementType {
    
    /// The Clean & Jerk movement, a two-part Olympic lift.
    case cleanAndJerk = "CleanAndJerk"
    
    /// The Snatch movement, an Olympic lift performed in one motion.
    case snatch = "Snatch"
    
    /// The Overhead Squat, a squat performed with the barbell overhead.
    case overheadSquat = "OverheadSquat"
    
    /// The Power Clean, a variation of the Clean where the lifter catches the bar in a higher position.
    case powerClean = "PowerClean"
    
    /// The Squat Clean, another name for the full Clean, where the lifter catches the bar in a deep squat.
    case squatClean = "SquatClean"
    
    /// The Split Jerk, a variation of the Jerk where the feet split apart during the catch phase.
    case splitJerk = "SplitJerk"

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
    
    /// A system symbol representing the movement.
    ///
    /// This computed property returns an appropriate SF Symbol for each weightlifting movement,
    /// providing a visual representation for improved user experience.
    var icon: String {
        switch self {
        case .cleanAndJerk:
            return "figure.clean.jerk"
        case .snatch:
            return "figure.snatch"
        case .overheadSquat:
            return "figure.squat"
        case .powerClean:
            return "figure.power.clean"
        case .squatClean:
            return "figure.squat.clean"
        case .splitJerk:
            return "figure.split.jerk"
        }
    }

    /// A description of the movement.
    ///
    /// This property provides a brief explanation of each weightlifting movement,
    /// highlighting its purpose and execution technique.
    var description: String {
        switch self {
        case .cleanAndJerk:
            return "A two-part Olympic lift that involves lifting the bar from the floor to the shoulders (clean) and then overhead (jerk). It requires strength, power, and coordination."
        case .snatch:
            return "An Olympic lift where the bar is lifted from the floor to overhead in one continuous motion. It demands flexibility, speed, and precision."
        case .overheadSquat:
            return "A squat performed while holding the barbell overhead with a wide grip. It tests balance, mobility, and strength, especially in the core and shoulders."
        case .powerClean:
            return "A variation of the clean where the lifter catches the bar in a higher position rather than a deep squat. It emphasizes explosive power and technique."
        case .squatClean:
            return "A full clean where the lifter catches the bar in a deep squat before standing up. It is essential for Olympic weightlifting and requires speed and mobility."
        case .splitJerk:
            return "A variation of the jerk where the lifter moves one foot forward and the other back to stabilize the bar overhead. It enhances balance and control during the lift."
        }
    }
    
    static func from(rawValue: String) -> WeightliftingMovement? {
        return WeightliftingMovement.allCases.first { $0.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame }
    }
}
