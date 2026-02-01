//
//  Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import ComposableArchitecture

/// Implementation of `ActivityDetailsFeature` destination
extension ActivityDetailsFeature {
    
    @Reducer
    enum Destination {
        
        ///
        case metricDetail(MetricDetailFeature)
        
    }
    
}
