//
//  ActivityFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ActivityFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .selectedPickerChange(period):
                    state.activityPeriod = period
                    return .none
                    
                    // MARK: - View Actions
                 
                case let .view(.tapWorkout(workout)):
                    return .send(.workoutSelected(workout))
                    
                case .view(.viewDidAppear):
                    print("ActivityFeature - viewDidAppear")
                    return .none
                    
                // MARK: - Destination
                    
                case let .workoutSelected(workout):
                    state.selectedWorkout = workout
                    if let workout {
                        return .send(.show(workout))
                    }
                    return .none
                    
                case let .show(workout):
                    state.destination = .detailItem(ActivityDetailsFeature.State(workout: workout))
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
//case .show(let author):
//    state.destination = .detailItem(AuthorDetailsFeature.State(author: author))
//    return .none
