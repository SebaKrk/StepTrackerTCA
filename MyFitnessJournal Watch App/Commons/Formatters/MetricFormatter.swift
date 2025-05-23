//
//  MetricFormatter.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation

struct MetricFormatter {
    static let workoutEnergy: Measurement<UnitEnergy>.FormatStyle = 
        .measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))
    
    static let heartRate: FloatingPointFormatStyle<Double> = 
        .number.precision(.fractionLength(0))
}
