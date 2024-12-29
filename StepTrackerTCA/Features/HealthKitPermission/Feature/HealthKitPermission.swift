//
//  HealthKitPermission.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HealthKitPermissionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View actions
                
            case .view(.appleHealthButtonPressed):
                state.isShowingHealthKitPermissions = true
                return .none
                
            case .view(.viewDidAppear):
                state.hasSeen = true
                return .none
            }
        }
    }
    
}
