//
//  DefaultWeightGoalWidgetService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import Foundation

final class DefaultWeightGoalWidgetService: WeightGoalWidgetService {
    
    // MARK: - API
    
    /// Calculates the minimum value from the provided health data.
    func calculateMinValue(from healthData: [HealthData]) -> Double {
        healthData.map { $0.value }.min() ?? 0
    }
    
    ///
    func selectedHealthMetric(from healthData: [HealthData], with rawSelectedDate: Date?) -> HealthData? {
        guard let rawSelectedDate else { return nil }
        return healthData.first {
            Calendar.current.isDate(rawSelectedDate, inSameDayAs: $0.date)
        }
    }
    
    ///
    func calculateWeightAverage(from data: [HealthData]) -> Double {
        guard !data.isEmpty else { return 0 }
        let average = data.reduce(0) { $0 + $1.value } / Double(data.count)
        return (average * 100).rounded() / 100
    }
    
}
