//
//  PrivacySettingsFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture

extension PrivacySettingsFeature {

    @Reducer
    enum Destination {

        /// Navigation to the diagnostics bundle screen.
        case diagnostics(DeveloperSettingsFeature)
    }
}
