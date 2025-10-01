//
//  StatsFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture

/// Implementation of `StatsFeature` destination
extension StatsFeature {
    
    @Reducer
    enum Destination {
        case personSettings(PersonSettingsFeature)
    }
}
