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
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `HealthMetricContext` representing the selected metric.
        case selectedPickerChange(HealthMetricContext)
        
        /// Path
        case path(StackActionOf<Path>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
