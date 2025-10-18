//
//  HealthMetricSummaryCardFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import ComposableArchitecture

/// Implementation of `HealthMetricSummaryCardFeature` destination
extension HealthMetricSummaryCardFeature {
    
    @Reducer
    enum Destination {
        
        ///
        case details(HealthMetricSummaryDetailsCardFeature)
    }
    
}
