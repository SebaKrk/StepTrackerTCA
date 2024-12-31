//
//  DashboardFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture

/// Implementation of `DashboardFeature` action
extension DashboardFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `HealthMetricContext` representing the selected metric.
        case selectedPickerChange(HealthMetricContext)
        
        // MARK: - Path
        
        /// Path
        case path(StackActionOf<Path>)
        
        // MARK: - Destination
        
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
