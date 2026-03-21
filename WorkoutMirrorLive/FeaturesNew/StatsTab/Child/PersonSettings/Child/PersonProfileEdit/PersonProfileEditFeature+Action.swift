//
//  PersonProfileEditFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import ComposableArchitecture

/// Implementation of `PersonProfileEditFeature` action
extension PersonProfileEditFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - Binding

        /// Handles direct state bindings from SwiftUI (e.g. TextField via $store.name)
        case binding(BindingAction<State>)

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Action triggered when save button is tapped
            case saveButtonTapped

            /// Action triggered when cancel button is tapped
            case cancelButtonTapped
        }

        // MARK: - Delegate

        /// Action to communicate results back to the parent feature
        case delegate(Delegate)

        enum Delegate {

            /// Notifies parent that profile was saved successfully
            case profileSaved
        }
    }

}
