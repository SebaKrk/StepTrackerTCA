//
//  WorkoutSession.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/03/2025.
//

import Foundation

/// A protocol representing a workout session.
///
/// This protocol defines the essential properties of a workout session, including
/// its unique identifier, type, movement category, associated value, and date.
/// Conforming types must provide these properties to standardize workout data handling.
///
/// - Conforms to: `Identifiable`, `Equatable`
protocol WorkoutSession: Identifiable, Equatable {
    
    /// A unique identifier for the workout session.
    ///
    /// This identifier ensures each session is uniquely distinguishable.
    var id: String { get }
    
    /// The type of workout performed in this session.
    ///
    /// Each workout session belongs to a specific `WorkoutType`, which determines
    /// its categorization and associated movement types.
    var workoutType: String  { get }
    
    /// The movement associated with this workout session.
    ///
    /// Each session involves a specific movement, which conforms to `MovementType`.
    var movement: String { get }
    
    /// A value associated with the workout session.
    ///
    /// This could represent the number of repetitions, duration, distance, or weight
    /// lifted, depending on the workout type.
    var value: String { get }
    
    /// The date when the workout session took place.
    ///
    /// Used for tracking workout history and progress over time.
    var date: Date { get }
    
}
