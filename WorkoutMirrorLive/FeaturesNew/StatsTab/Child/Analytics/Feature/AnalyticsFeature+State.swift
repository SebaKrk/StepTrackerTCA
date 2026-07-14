//
//  AnalyticsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

/// State container for `AnalyticsFeature`.
///
/// Holds shared subscription tier and optional child feature states.
/// Each child is `nil` until the analytics view appears and triggers initialization.
extension AnalyticsFeature {

    @ObservableState
    struct State {

        /// The user's current subscription tier.
        /// Persisted using `AppStorage` to survive app restarts.
        /// Used by child features to determine content gating (e.g., Readiness Trend requires Pro).
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        // MARK: - Child

        /// Child feature displaying weekly workout volume as a stacked bar chart.
        /// Available to all subscription tiers (Basic/free).
        /// `nil` until `initializeChildren` is dispatched.
        var workoutVolume: WorkoutVolumeFeature.State?

        /// Child feature displaying training readiness score trend over time.
        /// Requires Pro subscription tier.
        /// `nil` until `initializeChildren` is dispatched.
        var readinessTrend: ReadinessTrendFeature.State?

        /// Child feature displaying weight trend as a line chart.
        /// Available to all subscription tiers (Basic/free).
        /// `nil` until `initializeChildren` is dispatched.
        var weightTrend: WeightTrendFeature.State?

        /// Child feature displaying RHR, HRV, Sleep and Activity trends over time.
        /// Requires Elite subscription tier.
        /// `nil` until `initializeChildren` is dispatched.
        var healthMetricsTrend: HealthMetricsTrendFeature.State?
    }
}
