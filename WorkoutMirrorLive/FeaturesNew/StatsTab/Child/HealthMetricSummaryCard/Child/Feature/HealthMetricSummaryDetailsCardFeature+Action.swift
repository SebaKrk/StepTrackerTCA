
//
//  HealthMetricSummaryDetailsCardFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 11/01/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

/// Implementation of `HealthMetricSummaryDetailsCardFeature` action
extension HealthMetricSummaryDetailsCardFeature {

    public enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Internal Actions
        
        /// Internal business logic actions not directly triggered by user interaction
        case `internal`(Internal)
        
        /// Internal actions for managing data loading and state transitions
        public enum Internal {
            
            /// Updates the view state (loading, success, failed)
            ///
            /// - Parameter value: The new view state to transition to
            case changeViewState(ViewState)
            
            /// Triggers fetching of 7-day historical data for the current metric
            ///
            /// Initiates an async operation through `healthMetricHistoryClient` to fetch
            /// the last 7 days of data points for the metric specified in state.
            case loadHistoricalData
            
            /// Called when historical data has been successfully loaded
            ///
            /// - Parameter dataPoints: Array of 7 historical data points (may contain gaps/nil values)
            case historicalDataLoaded([HistoricalDataPoint])
            
            /// Called when data loading fails
            ///
            /// - Parameter error: The error that occurred during data fetching
            case loadingFailed(Error)
            
            /// Action triggered when the user selects a date on the chart.
            case selectedChartDateChange(Date?)
        }
        
        // MARK: - View Actions
        
        /// User-triggered actions from the view layer
        case view(View)
        
        /// View actions representing user interactions and lifecycle events
        public enum View {
            
            /// Action triggered when the view appears on the screen.
            ///
            /// This initiates the data loading process to fetch fresh historical data
            /// for the selected health metric.
            case viewDidAppear
        }
    }
}
