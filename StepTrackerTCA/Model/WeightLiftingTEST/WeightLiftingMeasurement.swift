//
//  WeightLiftingMeasurement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// A model representing a recorded weightlifting measurement.
///
/// This structure stores information about a specific weightlifting session,
/// including the movement type, recorded weight, measurement date, and an optional goal reference.
struct WeightLiftingMeasurement: Identifiable, Codable {
    
    /// A unique identifier for the measurement.
    let id: String
    
    /// The weightlifting movement associated with this measurement.
    let name: WeightliftingMovement
    
    /// The date when the measurement was recorded.
    let date: Date
    
    /// The measured value (e.g., weight lifted in kilograms or pounds).
    let value: Double
    
    /// An optional identifier linking the measurement to a weightlifting goal.
    ///
    /// If the measurement is associated with a specific goal, this property stores the goal’s ID.
    /// Otherwise, it remains `nil`.
    let goalId: String?
    
}
