//
//  DashboardFeature+Path.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DashboardFeature` path
extension DashboardFeature {
    
    @Reducer
    enum Path {
        
        ///
        case healthDataListFeature(HealthDataListFeature)
    }
    
}
