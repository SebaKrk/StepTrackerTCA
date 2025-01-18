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
    
    func addHealthData(for date: Date, value: Double, type: HKQuantityTypeIdentifier, unit: HKUnit) async throws {
        try await healthKitManager.addHealthData(for: date, value: value, type: type, unit: unit)
    }
}


