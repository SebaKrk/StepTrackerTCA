//
//  SessionCalculationsClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

struct SessionCalculationsClient {
    var calculateMaxHeartRate: (_ age: Int, _ gender: Gender?) -> Int
    var calculateHeartRateZone: (_ current: Int, _ max: Int) -> HeartRateZone
    var calculateHeartRatePercentage: (_ current: Int, _ max: Int) -> Int
    
    // New
    var calculateAverageHeartRate: (_ readings: [Int]) -> Int
    var calculateMaxHeartRateFromReadings: (_ readings: [Int]) -> Int
}

extension DependencyValues {
    var sessionCalculations: SessionCalculationsClient {
        get { self[SessionCalculationsClientKey.self] }
        set { self[SessionCalculationsClientKey.self] = newValue }
    }
}

private enum SessionCalculationsClientKey: DependencyKey {
    public static let liveValue: SessionCalculationsClient = {
        return SessionCalculationsClient(
            calculateMaxHeartRate: { age, gender in
                switch gender {
                case .female:
                    return Int(206 - (0.88 * Double(age)))
                case .male, .none:
                    return Int(208 - (0.7 * Double(age)))
                }
            },
            calculateHeartRateZone: { current, max in
                let percentage = Double(current) / Double(max)
                switch percentage {
                case 0.5...0.6: return .recovery
                case 0.6...0.7: return .fatBurning
                case 0.7...0.8: return .aerobic
                case 0.8...0.9: return .threshold
                case 0.9...1.0: return .anaerobic
                default: return .recovery
                }
            },
            calculateHeartRatePercentage: { current, max in
                let percentage = Double(current) / Double(max) * 100
                return Int(percentage)
            },
            calculateAverageHeartRate: { readings in
                guard !readings.isEmpty else { return 0 }
                let sum = readings.reduce(0, +)
                return sum / readings.count
            },
            calculateMaxHeartRateFromReadings: { readings in
                readings.max() ?? 0
            }
        )
    }()
    
}
