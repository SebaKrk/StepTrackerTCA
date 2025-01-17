//
//  DefaultStepPieWidget.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//
import Factory
import Foundation

final class DefaultStepPieWidget: StepPieWidgetService {
    
    // MARK: - Dependency
    
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - Properties
    
    // MARK: - API
    
    func calculateAverageHealthDataPerWeekday( _ healthData: [HealthData]) -> [WeekdayChartData] {
        healthKitManager.averageWeekdayCount(for: healthData)
    }
    
    func calculateTotalSteps(from data: [HealthData]) -> Double {
        return data.reduce(0) { $0 + $1.value }
    }
    
    func selectedWeekday(from healthData: [WeekdayChartData], with rawSelectedChartValue: Double?) -> WeekdayChartData? {
        guard let rawSelectedChartValue else { return nil }
        var total = 0.0
        
        return healthData.first {
            total += $0.value
            return rawSelectedChartValue <= total
        }
    }
}
