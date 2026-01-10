//
//  HealthMetricSummaryDetailsCardFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// A TCA feature that manages the detailed view of a specific health metric's historical data.
@Reducer
public struct HealthMetricSummaryDetailsCardFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.healthMetricHistoryClient) var healthMetricHistoryClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                            
            // MARK: - Internal Actions
                
            case let .internal(.changeViewState(value)):
                state.viewState = value
                return .none
                
            case .internal(.loadHistoricalData):
                return .run { [metricType = state.metricType] send in
                    do {
                        let dataPoints = try await healthMetricHistoryClient.fetchHistory(metricType, 7)
                        await send(.internal(.historicalDataLoaded(dataPoints)))
                    } catch {
                        await send(.internal(.loadingFailed(error)))
                    }
                }
                
            case let .internal(.historicalDataLoaded(dataPoints)):
                state.historicalValues = dataPoints
                return .run { send in
                    await send(.internal(.changeViewState(.success)))
                }
                
            case let .internal(.loadingFailed(error)):
                print("❌ Failed to load historical data: \(error)")
                return .run { send in
                    await send(.internal(.changeViewState(.failed)))
                }
                
            // MARK: - View Actions
                    
            case .view(.viewDidAppear):
                return .send(.internal(.loadHistoricalData))
            }
        }
    }
}

/// Implementation of `HealthMetricSummaryDetailsCardFeature` action
extension HealthMetricSummaryDetailsCardFeature {

    public enum Action: ViewAction {
        
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

/// Implementation of `HealthMetricSummaryDetailsCardFeature` state
extension HealthMetricSummaryDetailsCardFeature {

    @ObservableState
    public struct State: Equatable {
        
        // MARK: - Properties
        
        /// Current loading/success/failed state of the view
        ///
        /// - `.loading`: Initial state while fetching historical data
        /// - `.success`: Data loaded successfully, ready to display
        /// - `.failed`: Data loading failed, show error state
        var viewState: ViewState = .loading
        
        /// The type of health metric being displayed
        ///
        /// Determines which data source to query:
        /// - `.rhr`: Resting Heart Rate (bpm)
        /// - `.hrv`: Heart Rate Variability (ms)
        /// - `.sleep`: Sleep Duration (hours)
        /// - `.activity`: Active Energy Burned (kcal)
        let metricType: HealthMetricType
        
        /// Initial data shown as preview while loading fresh historical data
        ///
        /// Contains the summary score from the parent training readiness screen,
        /// providing immediate context to the user before detailed data loads:
        /// - Current value and baseline for quick reference
        /// - Score and status for contextual understanding
        /// - Allows instant display of basic info while fetching 7-day history
        let initialData: TrainingComponentScore
        
        /// Historical data points for the last 7 days
        ///
        /// Array of individual daily/nightly measurements ordered chronologically
        /// (oldest to newest). Used for:
        /// - Chart visualization (line charts, bar charts)
        /// - Trend analysis (improving/declining patterns)
        /// - Detailed day-by-day breakdown
        ///
        /// Empty array indicates data is still loading or fetch failed.
        var historicalValues: [HistoricalDataPoint] = []
    }
    
}
