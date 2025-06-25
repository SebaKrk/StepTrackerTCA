//
//  DefaultTrainingCalculationsService.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import Foundation
import SharedModels

final class DefaultTrainingCalculationsService: TrainingCalculationsService {
    
    // MARK: - Heart Rate Calculations
    
    func calculateMaxHeartRate(age: Int, gender: Gender? = nil) -> Int {
        switch gender {
        case .female:
            return Int(206 - (0.88 * Double(age)))
        case .male, .none:
            return Int(208 - (0.7 * Double(age)))
        }
    }
    
    func calculateHeartRateZone(current: Int, max: Int) -> HeartRateZone {
        let percentage = Double(current) / Double(max)
        switch percentage {
        case 0.5...0.6: return .recovery
        case 0.6...0.7: return .fatBurning
        case 0.7...0.8: return .aerobic
        case 0.8...0.9: return .threshold
        case 0.9...1.0: return .anaerobic
        default: return .recovery
        }
    }
    
    func calculateHeartRatePercentage(current: Int, max: Int) -> Int {
        let percentage = Double(current) / Double(max) * 100
        return Int(percentage)
    }
}
