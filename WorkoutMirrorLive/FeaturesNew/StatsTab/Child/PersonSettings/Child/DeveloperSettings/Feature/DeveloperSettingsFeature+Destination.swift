//
//  DeveloperSettingsFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture

/// Implementation of `DeveloperSettingsFeature` destination
extension DeveloperSettingsFeature {

    @Reducer
    enum Destination {

        /// Navigation to API key management screen
        case apiKey(APIKeyEntryFeature)
    }
}
