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
    
    /// Oblicza maksymalne tętno używając Strategy Pattern
    /// - Parameters:
    ///   - age: Wiek użytkownika
    ///   - biologicalSex: Płeć biologiczna użytkownika
    /// - Returns: Maksymalne tętno w uderzeniach na minutę
    public func calculateMaxHeartRate(age: Int, biologicalSex: BiologicalSex) -> Int {
        
        let strategy = selectStrategy(for: biologicalSex)
        return strategy.maxHR(for: age)
    }
    
    // MARK: - Strategy Pattern Implementation
    
    /// Strategy Pattern: Context Method
    /// Wybiera odpowiednią strategię (Concrete Strategy) na podstawie kontekstu
    private func selectStrategy(for biologicalSex: BiologicalSex) -> HeartRateFormula {
        switch biologicalSex {
        case .male:
            return FairbarnMaleFormula()
            
        case .female:
            return FairbarnFemaleFormula()
            
        case .notSet, .unknown:
            return FairbarnUnknownFormula()
        }
    }
}
