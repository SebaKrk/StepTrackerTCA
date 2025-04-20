//
//  DefaultStepPieWidget.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

final class DefaultStepPieWidget: StepPieWidgetService {
    
    // MARK: - API
    
    /// Calculates the average value of health data for each weekday.
    func calculateAverageHealthDataPerWeekday( _ healthData: [HealthData]) -> [WeekdayChartData] {
        let sortedByWeekday = healthData.sorted { $0.date.weekdayInt < $1.date.weekdayInt }
        let weekdayArray = sortedByWeekday.chunked { $0.date.weekdayInt == $1.date.weekdayInt }
        
        var weekdayChartData: [WeekdayChartData] = []
        
        for array in weekdayArray {
            guard let firstValue = array.first else { continue }
            let total = array.reduce(0) { $0 + $1.value }
            let avgSteps = total/Double(array.count)
            
            weekdayChartData.append(.init(date: firstValue.date, value: avgSteps))
        }
        
        return weekdayChartData
    }
    
    /// Calculates the total number of steps from an array of health data.
    func calculateTotalSteps(from data: [HealthData]) -> Double {
        return data.reduce(0) { $0 + $1.value }
    }
    
    /// Retrieves the weekday chart data corresponding to the selected chart value.
    func selectedWeekday(from healthData: [WeekdayChartData], with rawSelectedChartValue: Double?) -> WeekdayChartData? {
        guard let rawSelectedChartValue else { return nil }
        var total = 0.0
        
        return healthData.first {
            total += $0.value
            return rawSelectedChartValue <= total
        }
    }
}
