//
//  HealthMetricSummaryCardFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `HealthMetricSummaryCardFeature` state
extension HealthMetricSummaryCardFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic
        //@Shared var subscriptionTier: SubscriptionTier
        
        ///
        var requiredTier: SubscriptionTier = .elite
        
        ///
        var contentState: ContentState = .loading
        
        ///
        var components: TrainingReadinessComponents? = nil
        
        /// Represents the navigation destination state within `HealthMetricSummaryCardFeature`.
        /// This property handles transitions to different screens or modals within the feature.
        @Presents var destination: Destination.State?
    }
    
}
