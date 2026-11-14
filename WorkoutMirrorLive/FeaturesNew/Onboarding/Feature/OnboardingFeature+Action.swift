//
//  OnboardingFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture

/// Implementation of `OnboardingFeature` action
extension OnboardingFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - Actions

        /// The profile write finished, successfully or not.
        case saveFinished(Bool)

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Action triggered when the continue button is tapped.
            case continueTapped
        }

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {

            /// The profile is stored and the app can take over.
            case finished
        }
    }
}
