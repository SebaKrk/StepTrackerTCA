//
//  CurrentWeightService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import Foundation

protocol CurrentWeightService {
    
    /// Retrieves the latest body mass data from the provided list.
      /// - Parameter weightHealthData: An array of `HealthData` objects containing body mass records.
      /// - Returns: The latest `HealthData` object, or `nil` if no data is available.
      func getLatestWeightData(from weightHealthData: [HealthData]) -> HealthData?
    
}
