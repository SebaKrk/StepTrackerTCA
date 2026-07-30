//
//  WorkoutMirroringFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 25/06/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMirroringFeature` destination
extension WorkoutMirroringFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `HeartRateZoneInfoFeature`.
        case openHeartRateZoneInfo(HeartRateZoneInfoFeature)
    }
}
