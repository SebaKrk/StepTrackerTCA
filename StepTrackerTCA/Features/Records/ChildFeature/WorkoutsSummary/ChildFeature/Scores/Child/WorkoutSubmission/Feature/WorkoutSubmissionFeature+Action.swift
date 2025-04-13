//
//  WorkoutSubmissionFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/04/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutSubmissionFeature` action
extension WorkoutSubmissionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case addValue
        
        case view(View)
        
        enum View {
            case viewDidAppear
            case add
        }
    }
    
}
