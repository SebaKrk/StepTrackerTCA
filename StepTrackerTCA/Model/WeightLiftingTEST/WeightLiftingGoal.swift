//
//  WeightLiftingGoal.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// A model representing a weightlifting goal.
///
/// This structure defines a goal set by a user for a specific weightlifting movement,
/// including the target weight, measurement unit, and creation date.
struct WeightLiftingGoal: Identifiable, Codable {
    
    /// A unique identifier for the goal.
    let id: String
    
    /// The specific weightlifting movement this goal applies to.
    let movement: WeightliftingMovement
    
    /// The target weight the user aims to achieve for the movement.
    let target: Double
    
    /// The unit of measurement used for the target weight (e.g., kilograms, pounds).
    let unit: WeightUnit
    
    /// The date when the goal was created.
    let createdDate: Date
}
