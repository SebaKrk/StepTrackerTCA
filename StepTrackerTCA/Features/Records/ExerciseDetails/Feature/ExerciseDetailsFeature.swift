//
//  ExerciseDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ExerciseDetailsFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ExerciseDetailsFeature` action
extension ExerciseDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            case viewDidAppear
        }
    }
    
}


import ComposableArchitecture
import Foundation

/// Implementation of `ExerciseDetailsFeature` state
extension ExerciseDetailsFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
    }
}
