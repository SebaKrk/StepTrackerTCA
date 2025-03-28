//
//  GroupedMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/03/2025.
//

import Foundation

/// A structure representing a grouped collection of workout sessions by movement.
///
/// This structure is used to group multiple `WorkoutSession` instances that share the same `MovementType`.
/// It provides an easy way to categorize and organize workout data based on movement.
///
/// - Conforms to: `Identifiable`
struct GroupedMovement: Identifiable {
    
    /// A unique identifier for the grouped movement.
    ///
    /// The identifier is derived from the movement's title to ensure uniqueness.
    var id: String { movement.title }
    
    /// The movement associated with this grouped session.
    ///
    /// Defines the movement type for all sessions within this group.
    let movement: any MovementType
    
    /// A collection of workout sessions related to the movement.
    ///
    /// This stores all sessions that belong to the same movement category.
    let sessions: [any WorkoutSession]
    
    /// A collection of goals associated with the movement.
    ///
    /// This may be nil if no goals have been set by the user.
    let goals: [WorkoutGoal]?
    
}
