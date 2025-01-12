//
//  AppTabFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AppTabFeature` state
extension AppTabFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// List of available tabs in the application.
        ///
        /// The order of tabs determines their placement in the UI.
        var tabs: [AppScreen] = [.workout, .activity, .summary, .fuel, .community, .personData, .settings]
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.summary`.
        var selectedTab: AppScreen = .activity
        
        // MARK: - Children states
        
        /// Stores the information contained in the summaryTab: `DashboardFeature`.
        var summaryTab = DashboardFeature.State()
        
        /// Stores the information contained in the summaryTab: `WorkoutFeature`.
        var workoutTab = WorkoutFeature.State()
        
        /// Stores the information contained in the summaryTab: `ActivityFeature`.
        var activityTab = ActivityFeature.State()
        
    }
    
}
