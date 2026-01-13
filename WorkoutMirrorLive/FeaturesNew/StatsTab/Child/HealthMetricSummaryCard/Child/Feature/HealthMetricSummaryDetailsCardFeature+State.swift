//
//  HealthMetricSummaryDetailsCardFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 11/01/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

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
        
        var selectedDataPoint: HistoricalDataPoint?
        
        var rawSelectedDate: Date?
    }
    
}
