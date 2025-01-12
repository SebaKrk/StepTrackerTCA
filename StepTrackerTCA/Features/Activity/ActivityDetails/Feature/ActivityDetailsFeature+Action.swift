//
//  ActivityDetailsFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ActivityDetailsFeature` action
extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
