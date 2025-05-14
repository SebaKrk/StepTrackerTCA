//
//  WorkoutPlanerFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/05/2025.
//

import ComposableArchitecture
import Foundation
import WorkoutKit

@Reducer
struct WorkoutPlanerFeature {
    
    // MARK: - Dependencies
    
    let services: WorkoutPlanerService
    
    // MARK: - Livecycle
    
    init(service: WorkoutPlanerService = DefaultWorkoutPlanerService()) {
        self.services = service
    }
    
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
                case let .selectedWorkoutActivityPickerChange(item):
                    state.workoutActivityType = item
                    return .none
                    
                case let .selectedWorkoutLocationPickerChange(item):
                    state.workoutLocationType = item
                    return .none
                    
                case .createSingleWorkout:
                    return .run { [activity = state.workoutActivityType,
                                   location = state.workoutLocationType,
                                   goal = state.energyGoalValueToAdd] send in
                        let workout = services.createSingleWorkout(activity: activity, location: location, goal: goal)
                        await send(.updateWorkoutPlan(workout))
                    }
                    
                case let .updateWorkoutPlan(item):
                    state.workoutPlan =  WorkoutPlan(.goal(item))
                    return .none
                    
                case .updateWorkoutPreview:
                    state.showPreview.toggle()
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case .view(.createWorkoutButtonTapped):
                    return .send(.createSingleWorkout)
                    
                case .view(.showWorkoutPreview):
                    return .send(.updateWorkoutPreview)
                }
            }
        }
    }
    
}
