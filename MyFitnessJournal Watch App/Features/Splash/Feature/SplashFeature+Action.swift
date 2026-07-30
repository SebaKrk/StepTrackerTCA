//
//  SplashFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SplashFeature` state
extension SplashFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Handles user interactions and lifecycle events from the view layer.
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Triggered when the splash screen appears.
            case viewDidAppear
            
            /// Instructs to transition from the splash screen to the main application.
            case showMainApp
        }
    }
    
}
