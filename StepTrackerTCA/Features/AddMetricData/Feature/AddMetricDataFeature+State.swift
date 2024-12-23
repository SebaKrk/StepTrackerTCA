//
//  AddMetricDataFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AddMetricDataFeature` state
extension AddMetricDataFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// This value represents the health metric to display
        var healthMetric: HealthMetricContext?
        
        /// The date for which the user wants to add metric data.
        /// Defaults to the current date.
        var addDataDate: Date = .now
        
        /// The value to add for the selected health metric, entered as a string.
        var valueToAdd: String = ""
        
    }
    
}
