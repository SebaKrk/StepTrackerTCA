//
//  DefaultStepWidgetService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

final class DefaultStepWidgetService: StepWidgetService {
    
    // MARK: - API
    
    /// Retrieves the health metric that corresponds to the selected date.
    func selectedHealthMetric(from healthData: [HealthData], with rawSelectedDate: Date?) -> HealthData? {
        guard let rawSelectedDate else { return nil }
        return healthData.first {
            Calendar.current.isDate(rawSelectedDate, inSameDayAs: $0.date)
        }
    }
    
    /// Calculates the average step count from the given data.
    func calculateAverageStepCount(from data: [HealthData]) -> Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.value } / Double(data.count)
    }
    
}
