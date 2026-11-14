//
//  DeveloperSettingsFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DeveloperSettingsFeature` action
extension DeveloperSettingsFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Called when the diagnostics bundle finished building — `nil` on failure
        case diagnosticsBundleReady(URL?)

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Action triggered when API key row is tapped
            case apiKeyTapped

            /// Action triggered when the "attach database" switch is flipped.
            case includeDatabaseToggled

            /// Action triggered when the diagnostics row is tapped — builds the bundle.
            case sendDiagnosticsTapped

            /// Action triggered when the composer or share sheet closes, sent or not.
            case diagnosticsDeliveryDismissed
        }

        // MARK: - Destination

        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
