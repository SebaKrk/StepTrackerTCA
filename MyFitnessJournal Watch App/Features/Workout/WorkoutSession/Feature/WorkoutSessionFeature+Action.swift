//
//  WorkoutSessionFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

/// Implementation of `WorkoutSessionFeature` action
extension WorkoutSessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(WorkoutSessionScreenAW)
        
        ///
        case setWorkoutActivityType(HKWorkoutActivityType)
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case changeTab
        }
        
        // MARK: - Child Actions
        
        ///
        case controlsFeature(ControlsFeature.Action)
        
        ///
        case workoutMetricFeature(WorkoutMetricFeature.Action)
    }
    
}
