//
//  WeightGoalWidgetFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightGoalWidgetFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                print("WeightGoalWidgetFeature")
                return .none
            }
        }
    }
    
}
