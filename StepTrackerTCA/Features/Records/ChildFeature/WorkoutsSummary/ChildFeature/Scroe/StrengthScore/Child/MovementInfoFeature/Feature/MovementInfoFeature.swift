//
//  MovementInfoFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MovementInfoFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementInfoFeature` action
extension MovementInfoFeature {
    
    @CasePathable
    enum Action { }
}


import ComposableArchitecture
import Foundation

/// Implementation of `MovementInfoFeature` state
extension MovementInfoFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        let movement: any MovementType
    }
}
