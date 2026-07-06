//
//  PersonalActivityFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import AppDatabase
import ComposableArchitecture
import SharedModels
import SQLiteData
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

        /// Observed query (SQLiteData) — ONLY plan↔workout records with empty
        /// results (pending). SQLite performs the filter (review cluster E: filtering
        /// all records in Swift per render was O(records×rows)). The database itself
        /// pushes updates on every write (auto-link from C, saving results in Summary).
        /// `@ObservationStateIgnored` — FetchAll has its own observation (SharedReader).
        /// Pending = `resultsData == "[]"` — JSONEncoder emits exactly these 2 bytes
        /// for an empty array; all writes go through the same encoder.
        @ObservationStateIgnored
        @FetchAll(WorkoutPlanScoreRecord.where { $0.resultsData.eq(Data("[]".utf8)) })
        var pendingScores

        /// Workouts with an auto-linked plan but no results entered yet (IOS-00098-F).
        /// Drives the "Uzupełnij wyniki" badge on list rows.
        var pendingResultWorkoutIds: Set<UUID> {
            Set(pendingScores.map(\.hkWorkoutId))
        }

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
