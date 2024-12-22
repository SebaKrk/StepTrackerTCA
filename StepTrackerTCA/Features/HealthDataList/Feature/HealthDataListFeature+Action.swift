//
//  HealthDataListFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture

/// Implementation of `HealthDataListFeature` action
extension HealthDataListFeature {
    
    @CasePathable
    enum Action {
        
        // MARK: - Actions
        
        /// Use to navigate to HealthDataList
        case navigateToHealthDataList
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
     
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
