//
//  HeartRateCalculatorClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import ComposableArchitecture
import SharedModels
import HealthHub

public struct PersonCalculatorClient {
    
    /// Oblicza maksymalne tętno na podstawie wieku i płci biologicznej
    var calculateMaxHeartRate: @Sendable (Int, BiologicalSex) -> Int
    
}

extension DependencyValues {
    var personCalculatorClient: PersonCalculatorClient {
        get { self[PersonCalculatorKey.self] }
        set { self[PersonCalculatorKey.self] = newValue }
    }
}

private enum PersonCalculatorKey: DependencyKey {
    
    static let liveValue: PersonCalculatorClient = {
    
        @Dependency(\.heartRateCalculator) var calculator
        
        return PersonCalculatorClient(
            calculateMaxHeartRate: { age, sex in
                calculator.calculateMaxHeartRate(age: age, biologicalSex: sex)
            }
        )
    }()
    
}
