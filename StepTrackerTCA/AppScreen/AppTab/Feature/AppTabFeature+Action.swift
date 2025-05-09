//
//  AppTabFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AppTabFeature` action
extension AppTabFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(AppScreen)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Children actions
        
        /// Stores the actions of the summaryTab: `DashboardFeature`
        case summaryTab(DashboardFeature.Action)
        
        /// Stores the actions of the summaryTab: `WeightGoalTest`
        case workoutTab(WeightGoalTest.Action)
        
        /// Stores the actions of the summaryTab: `ActivityFeature`
        case activityTab(ActivityFeature.Action)
        
        /// Stores the actions of the summaryTab: `PersonDataFeature`
        case personDataTab(PersonDataFeature.Action)
    }
    
}
