//
//  DefaultHeartRateCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation
import SharedModels

@preconcurrency
public final class DefaultHeartRateCalculator: HeartRateCalculator, @unchecked Sendable  {
    
    public init() {}
    
    // MARK: - Public API

    /// Computes max HR using the chosen `formula` strategy.
    public func calculateMaxHeartRate(age: Int, biologicalSex: BiologicalSex, formula: HRFormulaType) -> Int {
        let strategy = selectStrategy(for: biologicalSex, formula: formula)
        return strategy.maxHR(for: age)
    }

    // MARK: - Strategy Pattern Implementation

    /// Strategy Pattern: primary switch on `formula` (selector), secondary on
    /// `biologicalSex` (only for sex-aware formulas like Fairbarn).
    ///
    /// Caller decides the formula — this method is pure dispatch.
    private func selectStrategy(for biologicalSex: BiologicalSex, formula: HRFormulaType) -> HeartRateFormula {
        switch formula {
        case .nes:
            return NesFormula()

        case .tanaka:
            return TanakaFormula()

        case .gulati:
            return GulatiFormula()

        case .fairbarn:
            switch biologicalSex {
            case .male:
                return FairbarnMaleFormula()
            case .female:
                return FairbarnFemaleFormula()
            case .notSet, .unknown:
                return FairbarnUnknownFormula()
            }

        case .classic:
            return ClassicFormula()
        }
    }
}
