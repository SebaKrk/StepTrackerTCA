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
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Properties
    
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
                    if !state.energyGoalValue.isEmpty {
                        return .send(.changePlanerState(.add))
                    } else {
                        return .send(.changePlanerState(.start))
                    }
                    
                    // MARK: - Actions
                case let .changePlanerState(viewState):
                    state.planerState = viewState
                    return .none
                    
                case .validate:
                    // TODO: Validate values to add
                    return .none
                    
                case let .selectedWorkoutActivityPickerChange(item):
                    state.workoutActivityType = item
                    return .none
                    
                case let .selectedWorkoutLocationPickerChange(item):
                    state.workoutLocationType = item
                    return .none
                    
                case .createSingleWorkout:
                    return .run { [activity = state.workoutActivityType,
                                   location = state.workoutLocationType,
                                   goal = state.energyGoalValue] send in
                        let workout = services.createSingleWorkout(activity: activity, location: location, goal: goal)
                        await send(.updateWorkoutPlan(workout))
                    }
                    
                case let .updateWorkoutPlan(item):
                    state.workoutPlan = WorkoutPlan(.goal(item))
                    return .send(.changePlanerState(.preview))
                    
                case .updateWorkoutPreview:
                    state.showPreview.toggle()
                    return .none
                    
                case .updateScheduleWorkout:
                    guard let workout = state.workoutPlan else { return .none }
                     let date = state.dateAndTime

                     return .run { _ in
                         await services.schedule(workout: workout, at: date)
                         await self.dismiss()
                     }
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case .view(.cancelButtonTapped):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.createWorkoutButtonTapped):
                    return .send(.createSingleWorkout)
                    
                case .view(.showWorkoutPreview):
                    return .send(.updateWorkoutPreview)
                    
                case .view(.userDidOpenPreview):
                    return .none
                    
                case .view(.userDidClosePreview):
                    state.seePreview.toggle()
                    return .send(.changePlanerState(.save))
                    
                case .view(.saveScheduleWorkoutButtonTapped):
                    return .send(.updateScheduleWorkout)
                }
            }
        }
    }
    
}
