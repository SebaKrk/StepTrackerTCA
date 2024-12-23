//
//  AddMetricDataFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AddMetricDataFeature` action
extension AddMetricDataFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case addDataButtonPressed
            
            ///
            case dismissButtonPressed
        }
    }
    
}
