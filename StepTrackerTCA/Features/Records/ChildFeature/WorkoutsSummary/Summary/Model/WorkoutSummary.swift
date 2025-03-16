//
//  WorkoutSummary.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A structure representing a workout summary.
///
/// `WorkoutSummary` stores a collection of workout sessions, allowing
/// for grouping and analysis. This structure can be used to present
/// user workout data in the application interface.
///
/// - Properties:
///   - workouts: An array containing workout sessions (`WorkoutSession`).
struct WorkoutSummary {
    let workouts: [any WorkoutSession]
}
