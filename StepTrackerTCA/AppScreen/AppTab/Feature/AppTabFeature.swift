//
//  AppTabFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppTabFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .tabChanged(tab):
                state.selectedTab = tab
                return .none
                
            case .summaryTab:
                return .none

            case .workoutTab:
                return .none
                
            case .activityTab:
                return .none
                
            case .personDataTab:
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
            }
        }
        Scope(state: \.summaryTab, action: \.summaryTab) {
            DashboardFeature(service: DefaultDashboardFeatureService())
        }
        Scope(state: \.workoutTab, action: \.workoutTab) {
            WorkoutFeature()
        }
        Scope(state: \.activityTab, action: \.activityTab) {
            ActivityFeature()
        }
        Scope(state: \.personDataTab, action: \.personDataTab) {
            PersonDataFeature()
        }
    }
    
}
