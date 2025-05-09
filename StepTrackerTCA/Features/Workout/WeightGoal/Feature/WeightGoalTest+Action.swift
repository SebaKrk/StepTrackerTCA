//
//  WorkoutFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalTest` action
extension WeightGoalTest {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case save
        
        case clearAndReload
        
        case updateCurrentWeight(Double)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            case saveGoalButtonPressed
            
            case viewDidAppear
        }
    }
    
}

