//
//  AddMetricDataFeature+Delegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AddMetricDataFeature` delegate
extension AddMetricDataFeature {
    
    /// A delegate enum to handle events related to `AddMetricDataFeature`.
    enum Delegate: Equatable {
        
        /// Triggered when the user saves health data.
        /// - Parameter healthData: An object containing health-related data.
        case save(HealthData)
    }
        
}
