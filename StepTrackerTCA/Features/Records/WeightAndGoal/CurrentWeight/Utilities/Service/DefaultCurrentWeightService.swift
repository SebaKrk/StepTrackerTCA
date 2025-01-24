//
//  DefaultCurrentWeightService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import Factory
import Foundation

final class DefaultCurrentWeightService: CurrentWeightService {
    
    // MARK: - API
    
    func getLatestWeightData(from weightHealthData: [HealthData]) -> HealthData? {
        guard let latestWeight = weightHealthData.last else {
            print("No body mass data available.")
            return nil
        }
        return latestWeight
    }
    
}
