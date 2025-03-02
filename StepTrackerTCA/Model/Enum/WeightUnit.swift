//
//  WeightUnit.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// An enumeration representing weight measurement units.
///
/// This enum defines the units used for measuring body weight.
/// It supports both kilograms (kg) and pounds (lbs).
enum WeightUnit: String, Codable, CaseIterable {
    
    /// Kilograms (kg) - the metric unit of weight.
    case kg = "kg"
    
    /// Pounds (lbs) - the imperial unit of weight.
    case lbs = "lbs"

    /// A human-readable label for the weight unit.
    ///
    /// This computed property returns a string representation of the unit,
    /// suitable for UI display.
    var label: String { rawValue }
    
}
