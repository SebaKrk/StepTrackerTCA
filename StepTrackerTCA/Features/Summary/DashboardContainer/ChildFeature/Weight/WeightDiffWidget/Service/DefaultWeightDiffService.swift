//
//  DefaultWeightDiffService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

final class DefaultWeightDiffService: WeightDiffService {
    
    // MARK: - API
    /// Retrieves the health metric that corresponds to the selected date.
    func selectedHealthMetric(from weekdayChartData: [WeekdayChartData], with rawSelectedDate: Date?) -> WeekdayChartData? {
        guard let rawSelectedDate else { return nil }
        return weekdayChartData.first {
            Calendar.current.isDate(rawSelectedDate, inSameDayAs: $0.date)
        }
    }

    func averageDailyWeightDiffs(for weights: [HealthData]) -> [WeekdayChartData] {
        guard weights.count > 1 else {
              return []
        }
        
        var diffValues: [(date: Date, value: Double)] = []
   
        for i in 1..<weights.count {
            let date = weights[i].date
            let diff = weights[i].value - weights[i - 1].value
            diffValues.append((date: date, value: diff))
        }

        let sortedByWeekday = diffValues.sorted { $0.date.weekdayInt < $1.date.weekdayInt }
        let weekdayArray = sortedByWeekday.chunked { $0.date.weekdayInt == $1.date.weekdayInt }
        var weekdayChartData: [WeekdayChartData] = []

        for array in weekdayArray {
            guard let firstValue = array.first else { continue }
            let total = array.reduce(0) { $0 + $1.value }
            let avgWeightDiff = total/Double(array.count)

            weekdayChartData.append(.init(date: firstValue.date, value: avgWeightDiff))
        }

        return weekdayChartData
    }
    
}
