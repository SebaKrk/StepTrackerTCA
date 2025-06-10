//
//  TrainingSummaryFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `TrainingSummaryFeature` state
extension TrainingSummaryFeature {
    @ObservableState
    struct State: Equatable {
        
        /// Represents the current state of the training summary view (e.g., loading, success, or failure).
        var viewState: TrainingSummaryState = .loading
        
        /// Holds the final summary of the workout, including data such as duration, distance, and calories.
        var summary: WorkoutSummary? = nil
        
        /// Contains the user's activity ring data for today, such as move, exercise, and stand metrics.
        /// This is set after successfully fetching data from HealthKit.
        var activityRingData: ActivityRingData? = nil
        
        /// Counts the number of times the system has retried fetching the workout summary.
        /// Used to limit the number of retry attempts before showing a failure state.
        var retryCount: Int = 0
    }
}
