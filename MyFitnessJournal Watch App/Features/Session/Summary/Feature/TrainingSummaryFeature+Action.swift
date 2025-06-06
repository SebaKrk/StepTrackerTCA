//
//  TrainingSummaryFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `TrainingSummaryFeature` state
extension TrainingSummaryFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Responsible for changing the state of the view.
        case changeViewState(TrainingSummaryState)
        
        /// Updates the summary state, typically used to hide or reset the summary screen.
        case changeSummaryState
        
        /// Initiates the workout summary check process. If the workout is ready, transitions to a loaded state; otherwise, begins a retry sequence.
        case checkWorkoutSummary

        /// Retries checking for the workout summary if the workout is not yet available. Waits 500ms between each attempt, up to a maximum retry limit.
        case retryWorkoutCheck

        /// Performs a single check for the workout summary. Called after a delay to see if the workout data has become available.
        case performWorkoutCheck
        
        /// Called when the workout summary has been successfully loaded.
        case workoutSummaryLoaded(WorkoutSummary)
        
        /// Starts the process of fetching today's activity ring data from HealthKit.
        case fetchTodaySummary
        
        /// Sets the activity ring data after successful fetch from HealthKit.
        case activityRingDataLoaded(ActivityRingData)
        
        /// Called when fetching the activity ring data fails.
        case failedToLoadRingData
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Called when the summary view appears. Triggers the initial check for the workout summary.
            case viewDidAppear
            
            /// Called when the user taps the Done button to close the summary view.
            case doneButtonPressed
        }
    }
    
}
