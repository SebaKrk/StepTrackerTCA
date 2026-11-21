//
//  PrivacySettingsFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PrivacySettingsFeature {

    @ObservableState
    struct State {

        // MARK: - Shared

        /// Whether the user agreed to send plans to the AI service; the switch that takes it back.
        @Shared(.appStorage(.aiProcessingConsent))
        var isAIProcessingAllowed = false

        // MARK: - Properties

        /// True while the server is erasing the account's cloud data.
        var isDeletingCloudData = false

        // MARK: - Destination

        /// Diagnostics screen pushed on top.
        @Presents var destination: Destination.State?

        /// Confirmation before the cloud data is erased, then its outcome.
        @Presents var alert: AlertState<Action.Alert>?
    }
}
