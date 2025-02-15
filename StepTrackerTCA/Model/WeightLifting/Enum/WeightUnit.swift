//
//  WeightUnit.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// An enumeration representing weight measurement units.
///
/// This enum defines the units used for weightlifting measurements and goals.
/// It supports both kilograms (kg) and pounds (lb).
enum WeightUnit: Codable {
    
    /// Kilograms (kg) - the metric unit of weight.
    case kg
    
    /// Pounds (lb) - the imperial unit of weight.
    case pound

    /// A human-readable label for the weight unit.
    ///
    /// This computed property returns a string representation of the unit,
    /// suitable for UI display.
    var label: String {
        switch self {
        case .kg:
            return "kg"
        case .pound:
            return "pound"
        }
    }
}
