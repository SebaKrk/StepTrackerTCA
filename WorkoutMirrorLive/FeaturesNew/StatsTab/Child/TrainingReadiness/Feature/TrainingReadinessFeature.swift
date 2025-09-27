//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrainingReadinessFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .internal(.readinessCalculated(value)):
                state.readinessValue = value
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
}
