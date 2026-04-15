//
//  ActivityPickerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct ActivityPickerFeature {
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .select(value):
                state.selected = value
                return .none
                
                // MARK: - View Action
            case let .view(.buttonTapped(value)):
                return .send(.select(value))
            }
        }
    }
}

/// Implementation of `ActivityPickerFeature` action
extension ActivityPickerFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case select(WorkoutType)
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            ///
            case buttonTapped(WorkoutType)
        }
    }
}

/// Implementation of `ActivityPickerFeature` state
extension ActivityPickerFeature {
    
    @ObservableState
    struct State {
        
        ///
        var workouts: [WorkoutType] = [.functional, .cross, .boxing, .cycling]
        
        ///
        var selected: WorkoutType? = nil
    }
    
}

