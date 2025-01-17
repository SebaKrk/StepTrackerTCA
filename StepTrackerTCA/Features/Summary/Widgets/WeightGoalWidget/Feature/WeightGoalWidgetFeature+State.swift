//
//  WeightGoalWidgetFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalWidgetFeature` state
extension WeightGoalWidgetFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The data for weight data, used to populate charts and other visualizations on the dashboard.
        var weightData: [HealthData] = []
        
        /// The minimum recorded weight value.
        /// - This value is derived from `weightData`.
        /// - Purpose: Used to display the lowest weight value within the recorded data.
        var weightMinValue: Double = 0
        
        /// The average weight calculated from `weightData`.
        /// - Purpose: Provides an insight into the average weight trend over time.
        var averageWeight: Double = 0
        
        /// The currently selected date for health data.
        /// Used to filter and display health metrics for a specific day.
        var rawSelectedDate: Date?
        
        /// The health metric corresponding to the selected date.
        /// This value is derived by matching `rawSelectedDate` with the `stepData` entries.
        var selectedHealthMetric: HealthData?
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
    }
}

