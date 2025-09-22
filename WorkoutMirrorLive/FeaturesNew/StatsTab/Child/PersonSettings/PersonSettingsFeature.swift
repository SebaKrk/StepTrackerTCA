//
//  PersonSettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PersonSettingsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.xMarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `PersonSettingsFeature` action
extension PersonSettingsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case xMarkButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `PersonSettingsFeature` state
extension PersonSettingsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        let age: Int? = nil
        
        // MARK: - Destination
        
        /// destination from PersonSettingsFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `PersonSettingsFeature` destination
extension PersonSettingsFeature {
    
    @Reducer
    enum Destination {

    }
}


