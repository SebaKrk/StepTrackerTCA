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
        /// User confirmed the HR device is (or will be) broadcasting — proceed.
        case confirmTapped
    }

    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - Action
            case let .select(option):
                state.selected = option
                return .none

            case .broadcastAlert(.presented(.confirmTapped)):
                return .send(.select(.iphone))

            case .broadcastAlert:
                return .none

                // MARK: - View Action
            case let .view(.buttonTapped(option)):
                guard option == .iphone else {
                    return .send(.select(option))
                }
                // "Other HR device" (Garmin/Polar/Suunto…) is invisible to the
                // iPhone until the user enables HR broadcasting on it — remind
                // BEFORE committing the choice, so a silent no-samples workout
                // never comes as a surprise. Cancel leaves nothing selected.
                state.broadcastAlert = AlertState {
                    TextState(String(localized: "Enable heart rate broadcasting"))
                } actions: {
                    ButtonState(action: .confirmTapped) {
                        TextState(String(localized: "OK"))
                    }
                    ButtonState(role: .cancel) {
                        TextState(String(localized: "Cancel"))
                    }
                } message: {
                    TextState(String(localized: "Turn on heart rate broadcasting on your device — on sport watches look for a setting like \"Broadcast Heart Rate\" (Garmin) or \"Share heart rate\" (Polar). Without it the iPhone will not receive any readings."))
                }
                return .none
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
    struct State {

        ///
        var selected: DeviceOption? = nil

        /// Shown when the user picks "Other HR device" — reminds them to enable
        /// HR broadcasting before the choice is committed.
        @Presents var broadcastAlert: AlertState<BroadcastAlertAction>?
    }
}
