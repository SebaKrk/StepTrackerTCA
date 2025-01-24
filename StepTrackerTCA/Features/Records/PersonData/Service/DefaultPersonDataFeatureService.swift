//
//  DefaultPersonDataFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import Factory
import Foundation

final class DefaultPersonDataFeatureService: PersonDataFeatureService {
    
    // MARK: - Dependency
    
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - API
    
    func getWeightData() async throws -> [HealthData] {
        return try await healthKitManager.fetchHealthData(for: .bodyMass,
                                                          days: 28,
                                                          unit: .gramUnit(with: .kilo),
                                                          options: .discreteAverage)
    }
    
}
