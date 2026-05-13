//
//  PersonalActivityFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI
import HealthKit
import HealthHub

extension PersonalActivityFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        /// Current view state (loading, success, or failed).
        var viewState: ViewState = .loading
        
        /// List of fetched workouts from HealthKit.
        var workouts: [HKWorkout] = []
        
        /// Number of days to look back when fetching workouts.
        var days: Int = 28
        
        /// Current sort option for ordering workouts.
        var sortDescriptors: ActivitiesSortOption = .newestFirst
        
        /// Per-workout max heart rate, keyed by `HKWorkout.uuid`.
        /// Computed from `birthDate + workout.startDate` via `MaxHeartRateClient`,
        /// so each row uses its historical maxHR (zones stable as user ages).
        var maxHRByWorkout: [UUID: Double] = [:]

        /// Heart rate zone information for each workout, keyed by workout UUID.
        var zoneInfo: [UUID: PrimaryZoneInfo] = [:]
        
        /// Workout selected for deletion — set when swipe action fires, cleared after confirm/cancel.
        var workoutToDelete: HKWorkout? = nil

        // MARK: - Alerts

        /// Confirmation alert before deleting workout from HealthKit.
        @Presents var deleteAlert: AlertState<Action.DeleteAlert>?

        /// Error alert shown when HealthKit rejects the deletion request.
        @Presents var errorAlert: AlertState<Never>?

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }
    
}
