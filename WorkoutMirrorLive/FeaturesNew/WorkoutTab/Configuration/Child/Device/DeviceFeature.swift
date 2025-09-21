//
//  DeviceFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct DeviceFeature {
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .select(option):
                state.selected = option
                return .none
                
                // MARK: - View Action
            case let .view(.buttonTapped(option)):
                return .send(.select(option))
            }
        }
    }
}

/// Implementation of `DeviceFeature` action
extension DeviceFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case select(DeviceOption)
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            ///
            case buttonTapped(DeviceOption)
        }
    }
}

/// Implementation of `DeviceFeature` state
extension DeviceFeature {
    
    @ObservableState
    struct State {
        
        ///
        var selected: DeviceOption? = nil
    }
}
