//
//  WorkoutSessionFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import Foundation
import Factory

@Reducer
struct WorkoutSessionFeature {
    
    // MARK: - Properties
    
    var service: WorkoutSessionService
    
    // MARK: - Lifecycle
    
    init(service: WorkoutSessionService = DefaultWorkoutSessionService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
            case let .setWorkoutActivityType(workoutActivityType):
                return .run { send in
                    service.updateWorkoutActivityType(workoutActivityType)
                }
            case let .tabChanged(tabItem):
                state.selectedTab = tabItem
                return .none
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                if let workout = state.selectedWorkout {
                    return .run { send in
                        await send(.setWorkoutActivityType(workout))
                    }
                }
                return .none
                
            case .view(.changeTab):
                state.selectedTab = .workout
                return .none
                
                // MARK: - Child Action
            case .controlsFeature(_):
                return .none
                
            case .workoutMetricFeature(_):
                return .none
            }
            
        }
        Scope(state: \.controlsFeature, action: \.controlsFeature) {
            ControlsFeature()
        }
        Scope(state: \.workoutMetricFeature, action: \.workoutMetricFeature) {
            WorkoutMetricFeature()
        }
    }
}
