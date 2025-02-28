//
//  DefaultAddMetricService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/01/2025.
//

import Factory
import Foundation
import HealthKit

final class DefaultAddMetricService: AddMetricService {
    
    // MARK: - Dependency
    
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - API
    
    /// Adds step count data to the HealthKit store for a specific date and value.
    func addSteps(for date: Date, value: Double) async throws {
        try await healthKitManager.addHealthData(for: date, value: value, type: .stepCount, unit: .count())
    }
    
    /// Adds body weight data to the HealthKit store for a specific date and value.
    func addWeight(for date: Date, value: Double) async throws {
        try await healthKitManager.addHealthData(for: date, value: value, type: .bodyMass, unit:  .gramUnit(with: .kilo))
    }
}


