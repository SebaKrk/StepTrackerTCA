//
//  ActivitiesFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/12/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI
import HealthKit
import HealthHub

/// Implementation of `ActivitiesFeature` state.
extension ActivitiesFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        /// Current view state (loading, success, or failed).
        var viewState: ViewState = .loading
        
        /// Selected tab context for filtering workouts.
        var context: TrainingTabContext = .activity
        
        /// List of fetched workouts from HealthKit.
        var workouts: [HKWorkout] = []
        
        /// Number of days to look back when fetching workouts.
        var days: Int = 28
        
        /// Current sort option for ordering workouts.
        var sortDescriptors: ActivitiesSortOption = .newestFirst
        
        /// User's maximum heart rate for zone calculations.
        var maxHeartRate: Double?
        
        /// Heart rate zone information for each workout, keyed by workout UUID.
        var zoneInfo: [UUID: PrimaryZoneInfo] = [:]
        
        // MARK: - Child Features
        
        /// State for the Plans tab.
        var plans: PlansFeature.State = PlansFeature.State()
        
        // MARK: - Destination
        
        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }
    
}

