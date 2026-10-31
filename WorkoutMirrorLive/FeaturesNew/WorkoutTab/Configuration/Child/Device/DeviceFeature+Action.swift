//
//  DeviceFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `DeviceFeature` action
extension DeviceFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Commits the device choice — the parent (`ConfigurationFeature`)
        /// listens to this to store the selection and advance the flow.
        case select(DeviceOption)

        /// Presentation lifecycle of the broadcast reminder alert.
        case broadcastAlert(PresentationAction<BroadcastAlertAction>)

        // MARK: - View Actions

        case view(View)

        // MARK: - View

        enum View {

            /// A device tile was tapped; sources that need preparing confirm through an alert first.
            case buttonTapped(DeviceOption)
        }
    }
}
