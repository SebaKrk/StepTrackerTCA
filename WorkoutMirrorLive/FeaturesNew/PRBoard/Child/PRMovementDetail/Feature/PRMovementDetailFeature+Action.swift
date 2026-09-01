//
//  PRMovementDetailFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture

extension PRMovementDetailFeature {

    @CasePathable
    enum Action: ViewAction {

        /// Actions sent by the view.
        case view(View)

        /// Forwards actions of the presented entry editor sheet.
        case editor(PresentationAction<PREntryEditorFeature.Action>)

        @CasePathable
        enum View {

            /// Opens the "add result" editor for this movement.
            case addEntryTapped
        }
    }
}
