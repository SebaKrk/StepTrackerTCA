//
//  PersonSettingsFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/09/2025.
//

import ComposableArchitecture

/// Implementation of `PersonSettingsFeature` destination
extension PersonSettingsFeature {

    @Reducer
    enum Destination {

        /// Navigation to API key management screen
        case apiKey(APIKeyEntryFeature)
    }
}


