//
//  WeightLiftingStatsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightLiftingStatsFeature {
    
    // MARK: - Dependencies
    
    let weightLiftingStatsServices: WeightLiftingStatsServices

    // MARK: - Livecycle
    
    init(service: WeightLiftingStatsServices) {
        self.weightLiftingStatsServices = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
            case .view(.navigationButtonTapped):
                return .send(.show)
                
                // MARK: - Destination
                
            case .show:
                state.destination = .open(WeightLiftingGoalsFeature.State())
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
