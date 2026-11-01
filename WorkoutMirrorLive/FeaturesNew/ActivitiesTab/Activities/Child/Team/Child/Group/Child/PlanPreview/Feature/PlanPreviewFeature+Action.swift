//
//  PlanPreviewFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PlanPreviewFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        case view(View)

        /// UI-only bindings (expanded cards).
        case binding(BindingAction<State>)

        /// Internal — the copy is saved in Plans.
        case downloaded

        /// Internal — saving failed; carries the message to show.
        case downloadFailed(String)

        /// Failure alert — OK only.
        case alert(PresentationAction<Alert>)

        /// Device picker presentation.
        case configuration(PresentationAction<ConfigurationFeature.Action>)

        /// The failure alert has no custom buttons.
        enum Alert: Equatable {}

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the user taps "Download to Plans".
            case downloadTapped

            /// Called when the user taps "Start Workout".
            case startWorkoutTapped

            /// Called when the user taps "Close".
            case closeTapped
        }

        @CasePathable
        enum Delegate {

            /// A local copy now exists.
            case downloaded

            /// The user chose a device — the parent starts the session on the saved copy.
            case startWorkout(DeviceOption)
        }
    }

}
