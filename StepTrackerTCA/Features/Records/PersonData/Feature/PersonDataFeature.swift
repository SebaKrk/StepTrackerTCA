//
//  PersonDataFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PersonDataFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                print("PersonDataFeature")
                return .none
                
                // MARK: - Destination
            case .destination:
                return .none
             
                // MARK: - Child actions
            case .currentWeight:
                return .none
                
            case .weightGoal:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Scope(state: \.currentWeight, action: \.currentWeight) {
            CurrentWeightFeature()
        }
        Scope(state: \.weightGoal, action: \.weightGoal) {
            WeightGoalFeature()
        }
        
    }
    
}
