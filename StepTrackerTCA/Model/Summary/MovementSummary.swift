//
//  MovementSummary.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/03/2025.
//

import Foundation

/// A summary of movement data for a specific type of movement.
/// This struct is generic over `T`, which conforms to `MovementType`.
///
/// - Parameters:
///   - T: A type conforming to `MovementType` that represents the specific movement type.
struct MovementSummary<T: MovementType>: Identifiable {
    
    /// Unique identifier for the movement summary.
    let id: String
    
    /// The movement type associated with this summary.
    let movement: T
    
    /// The goal for this movement, if applicable.
    let goal: Double?
    
    /// The latest recorded result for this movement.
    let latestResult: Double
}
