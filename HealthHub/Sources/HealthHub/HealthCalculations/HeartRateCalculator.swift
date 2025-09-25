//
//  HeartRateCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation
import SharedModels

public protocol HeartRateCalculator: Sendable {
    
    func calculateMaxHeartRate(age: Int, biologicalSex: BiologicalSex) -> Int
}
