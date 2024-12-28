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
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View actions
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}
