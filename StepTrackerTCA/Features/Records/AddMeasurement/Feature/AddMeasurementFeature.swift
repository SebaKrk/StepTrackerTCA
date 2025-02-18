//
//  AddMeasurementFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddMeasurementFeature {
    
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

/// Implementation of `AddMeasurementFeature` action
extension AddMeasurementFeature {
    
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

/// Implementation of `AddMeasurementFeature` state
extension AddMeasurementFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
    }
}

