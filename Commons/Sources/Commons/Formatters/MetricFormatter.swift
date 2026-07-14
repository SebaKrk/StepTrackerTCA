//
//  MetricFormatter.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation

public struct MetricFormatter {
    public static let workoutEnergy: Measurement<UnitEnergy>.FormatStyle =
        .measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))
    
    public static let heartRate: FloatingPointFormatStyle<Double> = 
        .number.precision(.fractionLength(0))
}
