//
//  HeartRateZoneInfoFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct HeartRateZoneInfoFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case .view(.selectedZoneDescription(let zone)):
                    if state.selectedZone == zone {
                        state.selectedZone = nil
                        state.descriptionIsExpanded = false
                    } else {
                        state.selectedZone = zone
                        state.descriptionIsExpanded = zone != nil
                    }
                    return .none
                }
            }
        }
    }
}

// MARK: - Action

/// Implementation of `HeartRateZoneInfoFeature` action
extension HeartRateZoneInfoFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// Action for selecting a zone and managing description expansion
            case selectedZoneDescription(HeartRateZone?)
        }
    }
}

// MARK: - State

/// Implementation of `HeartRateZoneInfoFeature` state
extension HeartRateZoneInfoFeature {
    
    @ObservableState
    struct State {
        
        /// Currently selected zone for description expansion
        var selectedZone: HeartRateZone?
        
        /// A Boolean value indicating whether the description view is expanded.
        var descriptionIsExpanded: Bool = false
    }
}
