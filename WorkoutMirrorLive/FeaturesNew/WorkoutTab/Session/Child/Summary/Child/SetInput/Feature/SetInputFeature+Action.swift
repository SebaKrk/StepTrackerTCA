//
//  SetInputFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension SetInputFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Binding actions for direct state mutations (TextField bindings).
        /// Prevents ifLet warning on dismiss — bindings go through BindingReducer
        /// which is synchronous, not through presentation layer.
        case binding(BindingAction<State>)

        // MARK: - View Actions

        case view(View)

        @CasePathable
        enum View {

            /// User tapped Add — save and dismiss.
            case addTapped

            /// User tapped Cancel — discard and dismiss.
            case cancelTapped
        }
    }
}
