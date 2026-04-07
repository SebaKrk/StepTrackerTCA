//
//  PersonalActivityFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import HealthKit
import SharedModels

extension PersonalActivityFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Changes the current view state (loading/success/failed).
        case changeViewState(ViewState)
        
        /// Triggers fetching workouts from HealthKit.
        case fetchWorkouts
        
        /// Handles the result of workout fetch operation.
        case workoutsFetched(Result<[HKWorkout], Error>)
        
        /// Triggers fetching user's max heart rate for zone calculations.
        case fetchMaxHeartRate
        
        /// Handles the result of max heart rate fetch.
        case maxHeartRateFetched(Double?)
        
        /// Handles the result of all workout zone analyses.
        case allWorkoutZonesAnalyzed([UUID: PrimaryZoneInfo])

        /// Triggered when workout deletion fails (e.g. not owned by this app).
        case deleteFailed
        
        // MARK: - View Actions
        
        case view(View)
        
        @CasePathable
        enum View {

            /// Triggered when the view appears on screen.
            case viewDidAppear

            /// Changes the number of days to fetch workouts for.
            case changeDays(Int)

            /// Changes the sort option for workouts list.
            case changeSortOption(ActivitiesSortOption)

            /// Opens workout details screen.
            case openDetails(HKWorkout)

            /// Shows heart rate zone info for the specified zone.
            case showZoneInfo(HeartRateZone)

            /// User swiped to delete — stores workout and shows confirmation alert.
            case deleteWorkoutSwiped(HKWorkout)

            /// User pulled to refresh the workouts list.
            case refresh
        }

        // MARK: - Alert

        case alert(PresentationAction<DeleteAlert>)

        @CasePathable
        enum DeleteAlert {
            case confirmDelete
        }

        /// Error alert shown when deletion is not permitted by HealthKit.
        case errorAlert(PresentationAction<Never>)

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }

}
