//
//  PlanPreviewFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation

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

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the user taps "Download to Plans".
            case downloadTapped

            /// Called when the user taps "Close".
            case closeTapped
        }

        @CasePathable
        enum Delegate {

            /// A local copy now exists.
            case downloaded
        }
    }

}
