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
                
            case .view(.testButtonTapped):
                return .send(.show)
                
            case .view(.viewDidAppear):
                print("WeightGoalFeature")
                return .none
                
                // MARK: - Destination
                
            case .show:
                state.destination = .detailItem(SetWeightGoalFeature.State())
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
