//
//  StatsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Implementation of `StatsFeature` state
extension StatsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic
        
        ///
        var viewState: ViewState = .loading
        
        /// The currently selected stats context display on the stats view.
        /// - Default: `.today`
        var context: StatsFeatureContext = .today
        
        
        // MARK: - Destination
        
        /// destination from SummaryFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        ///
        var trainingReadiness: TrainingReadinessFeature.State?
        
        ///
        var summaryCard: HealthMetricSummaryCardFeature.State?
        
        ///
        var ringActivitiesSummary: RingActivitiesSummaryFeature.State?
    }
    
}
