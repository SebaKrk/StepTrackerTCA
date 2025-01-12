//
//  WorkoutFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                print("WorkoutFeature - viewDidAppear")
                return .none
            }
        }
    }
    
}

