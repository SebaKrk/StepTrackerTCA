//
//  StatsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SharedModels
import HealthHub

/// Implementation of `StatsFeature` action
extension StatsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Updates the user's subscription tier in persistent storage.
        case changeSubscriptionTier(SubscriptionTier)
        
        /// Responsible for changing the state of the view.
        case changeViewState(ViewState)
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `StatsFeatureContext` representing the selected context.
        case selectedPickerChange(StatsFeatureContext)
        
        /// Updates the availability state of Apple Intelligence.
        case updateDataAnalyzer(Bool)
        
        /// Initializes all child features after successful authorization.
        case initializeChildren
        
        /// Initializes Training readiness calculator
        case initializeTrainingReadiness
        
        /// Initializes Health metric summary cards
        case initializeSummaryCard
        
        /// Initializes Activity ring summary
        case initializeRingActivitiesSummary

        /// Initializes the Analytics child feature (lazy, on first picker switch)
        case initializeAnalytics

        /// Initializes the Exercise Analytics child feature (lazy, on first picker switch)
        case initializeExerciseAnalytics
        
        /// Start observing real-time health data updates
        case startObserving
        
        /// Handle incoming health data update
        case healthDataUpdated(HealthDataUpdate)

        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            /// Action triggered when the view disappears from the screen.
            case viewDidDisappear
            
            /// Triggered when the user performs a pull-to-refresh gesture.
            /// Refreshes all child features and reloads the stats view content.
            case pullToRefresh
            
            /// Triggered when the user taps the person/profile button in the navigation bar.
            /// Typically opens the user settings screen.
            case personButtonTapped
            
            /// Triggered when the user selects a subscription tier option.
            /// Sends the chosen tier as an associated value.
            case subscriptionTierButtonTapped(SubscriptionTier)
            
            /// Checks whether the DataAnalyzer API is available on the current device (iOS 26+).
            case checkDataAnalyzerAvailability
            
            /// Triggered when user taps the Apple Intelligence button
            case dataAnalyzerButtonTapped

            /// Triggered when the user taps the PR Board button (Exercises segment only).
            case prBoardButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        /// Forwards actions to the TrainingReadinessFeature.
        /// Used to propagate user interactions and data updates to the child reducer.
        case trainingReadiness(TrainingReadinessFeature.Action)

        /// Forwards actions to the HealthMetricSummaryCardFeature.
        /// Handles updates affecting the statistics summary card.
        case summaryCard(HealthMetricSummaryCardFeature.Action)

        /// Forwards actions to the RingActivitiesSummaryFeature.
        /// Manages ring-based activity data and interactions within the stats screen.
        case ringActivitiesSummary(RingActivitiesSummaryFeature.Action)

        /// Forwards actions to the AnalyticsFeature.
        /// Handles historical trends and performance analysis within the analytics tab.
        case analytics(AnalyticsFeature.Action)

        /// Forwards actions to the ExerciseAnalyticsFeature.
        case exerciseAnalytics(ExerciseAnalyticsFeature.Action)

    }
    
}
