//
//  SetWeightGoalFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SetWeightGoalFeature {
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
}

/// Implementation of `SetWeightGoalFeature` action
extension SetWeightGoalFeature {
    
    @CasePathable
    enum Action { }
    
}

/// Implementation of `SetWeightGoalFeature` state
extension SetWeightGoalFeature {
    @ObservableState
    struct State { }
}
