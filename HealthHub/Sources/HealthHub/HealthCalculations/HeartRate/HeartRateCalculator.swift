//
//  HeartRateCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation
import SharedModels

public protocol HeartRateCalculator: Sendable {

    /// Computes max heart rate using the selected `formula` strategy.
    ///
    /// - Parameters:
    ///   - age: User's age in years (e.g., derived from HealthKit birth date).
    ///   - biologicalSex: User's biological sex from HealthKit.
    ///     Used only when `formula == .fairbarn` (sex-aware variants);
    ///     ignored by `.nes` and `.classic`.
    ///   - formula: Which formula strategy to apply.
    /// - Returns: Max heart rate in BPM.
    func calculateMaxHeartRate(age: Int, biologicalSex: BiologicalSex, formula: HRFormulaType) -> Int
}
