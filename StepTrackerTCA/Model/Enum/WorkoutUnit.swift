//
//  WorkoutUnit.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different units used for tracking workout performance.
///
/// This enum provides units for measuring repetitions and time-based exercises.
/// It ensures consistency in tracking various workout metrics.
enum WorkoutUnit: Codable, CaseIterable {
    
    /// Repetitions (Reps) - The number of times an exercise is performed.
    case reps
    
    /// A user-friendly label for the unit.
    ///
    /// This computed property returns a string representation of the unit,
    /// suitable for UI display.
    var label: String {
        switch self {
        case .reps:
            return "Reps"
        }
    }
}
