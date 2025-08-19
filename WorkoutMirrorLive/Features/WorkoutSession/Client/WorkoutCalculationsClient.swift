//
//  WorkoutCalculationsClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

struct WorkoutCalculationsClient {
    
    var calculateMaxHeartRate: (_ age: Int, _ gender: Gender?) -> Int
    var calculateHeartRateZone: (_ current: Int, _ max: Int) -> HeartRateZone
    var calculateHeartRatePercentage: (_ current: Int, _ max: Int) -> Int
}

extension DependencyValues {
    var workoutCalculations: WorkoutCalculationsClient {
        get { self[WorkoutCalculationsClientKey.self] }
        set { self[WorkoutCalculationsClientKey.self] = newValue }
    }
}

private enum WorkoutCalculationsClientKey: DependencyKey {
    public static let liveValue: WorkoutCalculationsClient = {
        
        return WorkoutCalculationsClient(
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
            }
        )
    }()
}

//    public init(
//        calculateMaxHeartRate: @escaping (_ age: Int, _ gender: Gender?) -> Int,
//        calculateHeartRateZone: @escaping (_ current: Int, _ max: Int) -> HeartRateZone,
//        calculateHeartRatePercentage: @escaping (_ current: Int, _ max: Int) -> Int
//    ) {
//        self.calculateMaxHeartRate = calculateMaxHeartRate
//        self.calculateHeartRateZone = calculateHeartRateZone
//        self.calculateHeartRatePercentage = calculateHeartRatePercentage
//    }
