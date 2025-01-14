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
    
    // TODO: - Refactor
    // Steps

    func getStepsData() async throws -> [HealthData] {
        return try await healthKitManager.fetchHealthData(for: .stepCount,
                                                          days: 28,
                                                          unit: .count(),
                                                          options: .cumulativeSum)
    }
    
    func calculateAverageStepCount(from data: [HealthData]) -> Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.value } / Double(data.count)
    }
    
    func calculateTotalSteps(from data: [HealthData]) -> Double {
        return data.reduce(0) { $0 + $1.value }
    }
    
    func selectedHealthMetric(from healthData: [HealthData], with rawSelectedDate: Date?) -> HealthData? {
        guard let rawSelectedDate else { return nil }
        return healthData.first {
            Calendar.current.isDate(rawSelectedDate, inSameDayAs: $0.date)
        }    
    }
    
    func selectedWeekday(from healthData: [WeekdayChartData], with rawSelectedChartValue: Double?) -> WeekdayChartData? {
        guard let rawSelectedChartValue else { return nil }
        var total = 0.0
        
        return healthData.first {
            total += $0.value
            return rawSelectedChartValue <= total
        }
    }
    
    func calculateAverageHealthDataPerWeekday( _ healthData: [HealthData]) -> [WeekdayChartData] {
        healthKitManager.averageWeekdayCount(for: healthData)
    }
    
    // TODO: - Refactor
    // Weight
    
    func getWeightData() async throws -> [HealthData] {
        return try await healthKitManager.fetchHealthData(for: .bodyMass,
                                                          days: 28,
                                                          unit: .gramUnit(with: .kilo),
                                                          options: .discreteAverage)
    }
    
    func calculateWeightAverage(from data: [HealthData]) -> Double {
        guard !data.isEmpty else { return 0 }
        let average = data.reduce(0) { $0 + $1.value } / Double(data.count)
        return (average * 100).rounded() / 100
    }
    
    func calculateMinValue(from healthData: [HealthData]) -> Double {
        healthKitManager.calculateMinValue(from: healthData)
    }
    
    func getDummyData() async throws {
        try await healthKitManager.addSimulatorData()
    }
    
}
