//
//  StepWidgetFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StepWidgetFeature` state
extension StepWidgetFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The data for steps, used to populate charts and other visualizations on the dashboard.
        var stepData: [HealthData] = []
        
        /// The average step count calculated from `stepData`.
        /// This value is derived to provide quick insights to the user, such as the average number of steps taken over a days
        var avgStepCount: Double = 0
        
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

