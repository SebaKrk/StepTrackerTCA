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
                    state.broadcastAlert = broadcastReminderAlert()
                    return .none
                case .airPods:
                    state.broadcastAlert = airPodsReminderAlert()
                    return .none
                default:
                    return .send(.select(option))
                }
            }
        }
        .ifLet(\.$broadcastAlert, action: \.broadcastAlert)
    }

    /// "Other HR device" (Garmin/Polar/Suunto…) is invisible to the iPhone until
    /// the user enables HR broadcasting on it.
    private func broadcastReminderAlert() -> AlertState<BroadcastAlertAction> {
        AlertState {
            TextState(String(localized: "Enable heart rate broadcasting"))
        } actions: {
            ButtonState(action: .confirmTapped(.iphone)) {
                TextState(String(localized: "OK"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "Turn on heart rate broadcasting on your device — on sport watches look for a setting like \"Broadcast Heart Rate\" (Garmin) or \"Share heart rate\" (Polar). Without it the iPhone will not receive any readings."))
        }
    }

    /// Heart rate on AirPods is a Pro 3 (2025) feature — only surfaces during a
    /// workout, and only with both buds in the ears and paired to this iPhone.
    private func airPodsReminderAlert() -> AlertState<BroadcastAlertAction> {
        AlertState {
            TextState(String(localized: "AirPods Pro 3 required"))
        } actions: {
            ButtonState(action: .confirmTapped(.airPods)) {
                TextState(String(localized: "OK"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "Heart rate is measured only by AirPods Pro 3. Put both AirPods in your ears and keep them connected to this iPhone — readings appear once the workout starts."))
        }
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
