//
//  WeightGoalFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightGoalFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.navigationButtonTapped):
                return .send(.show)
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
                
            case .show:
                state.destination = .setWeightGoal(SetWeightGoalFeature.State())
                return .none
                
            case let .destination(.presented(.setWeightGoal(.delegate(.setGoal(data))))):
                state.weightGoal = data
                return .none
                
            default: return .none      
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
