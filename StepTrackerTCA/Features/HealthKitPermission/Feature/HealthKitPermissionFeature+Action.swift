//
//  HealthKitPermissionFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `HealthKitPermissionFeature` action
extension HealthKitPermissionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Action
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
     
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
