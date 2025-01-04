//
//  DefaultDashboardFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Factory
import Foundation

final class DefaultDashboardFeatureService: DashboardFeatureService {
    
    // MARK: - Dependency
    
    @Injected(\.userDefaultsService) private var userDefaultsService
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - Properties
    
    var hasSeenPermissionPriming: Bool {
        userDefaultsService.get(objectForKey: .hasSeenPermissionPriming) ?? false
    }
    
    func markPermissionPrimingAsSeen() {
        userDefaultsService.set(true, forKey: .hasSeenPermissionPriming)
    }
    
    func getStepsData() async throws -> [HealthData] {
        return try await healthKitManager.fetchHealthData(for: .stepCount,
                                                   days: 28,
                                                   unit: .count())
    }
    
    func getDummyData() async throws {
        try await healthKitManager.addSimulatorData()
    }
    
}
