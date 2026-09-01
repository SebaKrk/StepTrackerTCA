//
//  PRMovementDetailFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PRMovementDetailFeature {

    @CasePathable
    enum Action: ViewAction {

        /// Actions sent by the view.
        case view(View)

        /// Forwards actions of the presented entry editor sheet.
        case editor(PresentationAction<PREntryEditorFeature.Action>)

        /// Forwards actions of the delete-confirmation dialog.
        case confirmationDialog(PresentationAction<Dialog>)

        @CasePathable
        enum View {

            /// Opens the "add result" editor for this movement.
            case addEntryTapped

            /// Asks to delete one history entry — shows the confirmation dialog.
            case deleteEntryTapped(PREntry)
        }

        @CasePathable
        enum Dialog {

            /// User confirmed deleting the entry with this id.
            case confirmDelete(UUID)
        }
    }
}
