//
//  PrivacySettingsFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import Foundation

extension PrivacySettingsFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Called when the user switches AI processing of plans on or off.
            case aiProcessingToggled(Bool)

            /// Called when the Diagnostics row is tapped — opens the diagnostics bundle screen.
            case diagnosticsTapped

            /// Called when the user asks to erase their cloud data — shows the confirmation.
            case deleteCloudDataTapped
        }

        // MARK: - Internal Actions

        /// Called when the erase of the account's cloud data finishes, either way.
        case cloudDataDeleted(Result<Void, any Error>)

        // MARK: - Destination

        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        // MARK: - Alert

        /// Action to handle the alerts of this feature.
        case alert(PresentationAction<Alert>)

        enum Alert {

            /// Called when the user confirms taking back the consent to AI processing.
            case aiProcessingTurnOffConfirmed

            /// Called when the user confirms erasing their cloud data.
            case deleteCloudDataConfirmed
        }
    }
}
