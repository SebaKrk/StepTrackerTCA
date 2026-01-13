//
//  SettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 22/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    
    // MARK: - Dependency
    
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

/// Implementation of `SettingsFeature` action
extension SettingsFeature {
    
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

/// Implementation of `SettingsFeature` state
extension SettingsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from SettingsFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `SettingsFeature` destination
extension SettingsFeature {
    
    @Reducer
    enum Destination {
        
    }
}
