//
//  StepPieWidgetFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StepPieWidgetFeature` state
extension StepPieWidgetFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The data for steps, used to populate charts and other visualizations on the dashboard.
        var stepData: [HealthData] = []
        
        /// Contains step data aggregated per weekday.
        /// This is used to display weekly step trends, such as average steps taken on each day of the week.
        var stepDataPerWeekDay: [WeekdayChartData] = []
        
        /// The structured representation of the selected chart value.
        /// Used to display detailed information about the user's activity or health data for the selected day.
        var selectedChartValue: WeekdayChartData?
        
        /// Represents the raw value of the selected chart data.
        var rawSelectedChartValue: Double? = 0
        
        /// The total number of steps calculated from the last 28 days.
        var totalStepsFrom28Days: Double = 0
        
    }
    
}
