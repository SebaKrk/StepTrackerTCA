//
//  WorkoutMirroringFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/08/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutMirroringFeature` destination
extension WorkoutMirroringFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `HeartRateZoneInfoFeature`.
        case heartRateZoneInfo(HeartRateZoneInfoFeature)
        
    }
}
