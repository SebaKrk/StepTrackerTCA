//
//  WeightLiftingGoalsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightLiftingGoalsFeature {
    
    // MARK: - Dependencies
    
    let weightLiftingGoalsServices: WeightLiftingGoalsServices

    // MARK: - Livecycle
    
    init(service: WeightLiftingGoalsServices = DefaultWeightLiftingGoalsServices()) {
        self.weightLiftingGoalsServices = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
                
            case .show:
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
