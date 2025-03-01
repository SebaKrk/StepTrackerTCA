//
//  WeightBarWidgetFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightDiffWidgetFeature` state
extension WeightDiffWidgetFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The data for weight data, used to populate charts and other visualizations on the dashboard.
        var weightData: [HealthData] = []
        
        /// Contains weight data aggregated per weekday.
        /// This is used to display weekly weight trends, such as average or fluctuations in weight recorded on each day of the week.
        var weightDataPerWeekDay: [WeekdayChartData] = []
        
        /// The currently selected date for health data.
        /// Used to filter and display health metrics for a specific day.
        var rawSelectedDate: Date?
        
        /// The health metric corresponding to the selected date.
        /// This value is derived by matching `rawSelectedDate` with the `WeekdayChartData` entries.
        var selectedHealthMetric: WeekdayChartData?
        
    }
    
}
