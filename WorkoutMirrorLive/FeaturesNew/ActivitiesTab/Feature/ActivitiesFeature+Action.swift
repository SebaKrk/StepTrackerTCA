//
//  ActivitiesFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 15/12/2025.
//

import ComposableArchitecture
import HealthKit
import SharedModels

/// Implementation of `ActivitiesFeature` actions.
extension ActivitiesFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Updates the selected tab context (personal/team).
        case selectedPickerChange(TrainingTabContext)
        
        /// Changes the current view state (loading/success/failed).
        case changeViewState(ViewState)
        
        /// Triggers fetching workouts from HealthKit.
        case fetchWorkouts
        
        /// Handles the result of workout fetch operation.
        case workoutsFetched(Result<[HKWorkout], Error>)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Triggered when the view appears on screen.
            case viewDidAppear
            
            /// Changes the number of days to fetch workouts for.
            case changeDays(Int)
            
            /// Changes the sort option for workouts list.
            case changeSortOption(ActivitiesSortOption)
        }
        
        // MARK: - Destination
        
        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
