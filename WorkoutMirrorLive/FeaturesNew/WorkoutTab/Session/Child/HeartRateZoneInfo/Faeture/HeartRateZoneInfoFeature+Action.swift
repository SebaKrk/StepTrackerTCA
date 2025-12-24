//
//  HeartRateZoneInfoFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import SharedModels

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
