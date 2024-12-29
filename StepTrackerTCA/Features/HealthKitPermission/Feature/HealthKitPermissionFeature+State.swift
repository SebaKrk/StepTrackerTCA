//
//  HealthKitPermissionFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture

/// Implementation of `HealthKitPermissionFeature` state
extension HealthKitPermissionFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        var isShowingHealthKitPermissions: Bool = false
        
        var hasSeen: Bool = false
        
    }
    
}
