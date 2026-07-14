//
//  StatsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// State container for `StatsFeature`.
/// Holds all UI-related and child-feature states, synchronization flags,
/// and shared values required to render the statistics view.
extension StatsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        /// The user's current subscription tier.
        /// Persisted using `AppStorage` to survive app restarts and sync with settings UI.
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic
        
        /// Current loading status of the stats screen.
        /// Used to drive UI states such as loading, success, and error views.
        var viewState: ViewState = .loading
        
        /// Defines which time period the statistics screen should display,
        /// such as daily, weekly, or monthly metrics.
        /// Defaults to `.today`.
        var context: StatsFeatureContext = .today
        
        /// Indicates whether the advanced DataAnalyzer API is available on the device.
        /// (iOS 26+ only)
        var isDataAnalyzerAvailable: Bool = false

        // MARK: - Pull-to-refresh coordination

        /// Number of child features that have signalled `.refreshDidComplete`
        /// since the most recent `pullToRefresh` action.
        var refreshCompletionsReceived: Int = 0

        /// Number of child features expected to signal `.refreshDidComplete`
        /// for the current refresh cycle. `0` means no refresh in progress.
        var refreshCompletionsExpected: Int = 0

        // MARK: - Destination
        
        /// Navigation destination controlled by the stats view.
        /// Used to present sheets or pushes defined in `Destination`.
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        /// Child feature responsible for training readiness calculations and display.
        var trainingReadiness: TrainingReadinessFeature.State?

        /// Child feature providing daily/weekly metric summaries used in the main card UI.
        var summaryCard: HealthMetricSummaryCardFeature.State?

        /// Child feature responsible for aggregating and presenting ring‑based activity data.
        var ringActivitiesSummary: RingActivitiesSummaryFeature.State?

        /// Child feature for the Analytics tab — historical trends and performance analysis.
        var analytics: AnalyticsFeature.State?

        /// Child feature for the Exercises tab — per-exercise tracking, movement balance.
        var exerciseAnalytics: ExerciseAnalyticsFeature.State?
    }
    
}
