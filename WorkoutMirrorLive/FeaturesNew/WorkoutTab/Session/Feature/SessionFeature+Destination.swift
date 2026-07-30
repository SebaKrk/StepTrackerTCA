//
//  SessionFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture

/// Implementation of `SessionFeature` destination
extension SessionFeature {
    
    @Reducer
    enum Destination {

        /// Represents the destination for displaying in `HeartRateZoneInfoFeature`.
        case openHeartRateZoneInfo(HeartRateZoneInfoFeature)
    }
}
