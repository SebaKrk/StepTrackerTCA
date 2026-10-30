//
//  DeviceFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct DeviceFeature {

    /// Broadcast reminder alert buttons — used by `AlertState<BroadcastAlertAction>`.
    enum BroadcastAlertAction: Equatable {
        /// User confirmed the picked HR source is (or will be) ready — proceed
        /// with that exact option (broadcasting device, or AirPods worn & paired).
        case confirmTapped(DeviceOption)
    }

    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - Action
            case let .select(option):
                state.selected = option
                return .none

            case let .broadcastAlert(.presented(.confirmTapped(option))):
                return .send(.select(option))

            case .broadcastAlert:
                return .none

                // MARK: - View Action
            case let .view(.buttonTapped(option)):
                // Sources that are silent until the user prepares them get a
                // reminder BEFORE the choice is committed, so a no-readings
                // workout never comes as a surprise. Cancel leaves nothing
                // selected. Everything else selects immediately.
                switch option {
                case .iphone:
                    state.broadcastAlert = .broadcastReminder
                    return .none
                case .airPods:
                    state.broadcastAlert = .airPodsReminder
                    return .none
                default:
                    return .send(.select(option))
                }
            }
        }
        .ifLet(\.$broadcastAlert, action: \.broadcastAlert)
    }
}

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

        enum View {

            ///
            case buttonTapped(DeviceOption)
        }
    }
}

/// Implementation of `DeviceFeature` state
extension DeviceFeature {

    @ObservableState
    struct State: Equatable {

        ///
        var selected: DeviceOption? = nil

        /// Shown when the user picks "Other HR device" — reminds them to enable
        /// HR broadcasting before the choice is committed.
        @Presents var broadcastAlert: AlertState<BroadcastAlertAction>?
    }
}
