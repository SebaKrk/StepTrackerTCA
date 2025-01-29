//
//  HealthKitPermissionFeature+Delegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/01/2025.
//


/// Implementation of `HealthKitPermissionFeature` delegate
extension HealthKitPermissionFeature {
    
    /// A delegate enum to handle events related to `HealthKitPermissionFeature`.
    enum Delegate: Equatable {
        
        ///
        case success
    }
        
}

/// Triggered when the user set weight goal.
/// - Parameter healthData: An object containing health-related data.
