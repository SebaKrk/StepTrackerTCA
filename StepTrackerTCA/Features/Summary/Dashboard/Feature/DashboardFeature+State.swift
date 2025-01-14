//
//  DashboardFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DashboardFeature` state
extension DashboardFeature {
    
    @ObservableState
    struct State {
        
        /// The currently selected health metric to display on the dashboard.
        /// - Default: `.steps`
        var healthMetric: HealthMetricContext = .steps
        
        /// Indicates whether the user has seen the permission priming screen.
        /// This flag is used to determine if the app should display a primer before requesting permissions.
        var hasSeenPermissionPriming: Bool = false
        
        /// The data for steps, used to populate charts and other visualizations on the dashboard.
        var stepData: [HealthData] = []
        
        /// Contains step data aggregated per weekday.
        /// This is used to display weekly step trends, such as average steps taken on each day of the week.
        var stepDataPerWeekDay: [WeekdayChartData] = []
        
        /// The average step count calculated from `stepData`.
        /// This value is derived to provide quick insights to the user, such as the average number of steps taken over a days
        var avgStepCount: Double = 0
        
        /// The currently selected date for health data.
        /// Used to filter and display health metrics for a specific day.
        var rawSelectedDate: Date?
        
        /// The health metric corresponding to the selected date.
        /// This value is derived by matching `rawSelectedDate` with the `stepData` entries.
        var selectedHealthMetric: HealthData?
        
        /// Represents the raw value of the selected chart data.
        var rawSelectedChartValue: Double? = 0
        
        /// The structured representation of the selected chart value.
        /// Used to display detailed information about the user's activity or health data for the selected day.
        var selectedChartValue: WeekdayChartData?
        
        /// The total number of steps calculated from the last 28 days.
        var totalStepsFrom28Days: Double = 0
        
        /// The data for weight data, used to populate charts and other visualizations on the dashboard.
        var weightData: [HealthData] = []
        
        /// The minimum recorded weight value.
        /// - This value is derived from `weightData`.
        /// - Purpose: Used to display the lowest weight value within the recorded data.
        var weightMinValue: Double = 0
        
        /// The average weight calculated from `weightData`.
        /// - Purpose: Provides an insight into the average weight trend over time.
        var averageWeight: Double = 0
        
        // MARK: - Path
        
        /// Path from DashboardFeature
        var path = StackState<Path.State>()
        
        // MARK: - Destination
        
        /// destination from DashboardFeature
        @Presents var destination: Destination.State?
    }
    
}
