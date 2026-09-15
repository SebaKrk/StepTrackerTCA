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

        /// Delete effect failed — presents the delete-failure alert.
        case deleteFailed

        /// Presentation actions of the delete-failure alert.
        case alert(PresentationAction<Alert>)

        /// Alert has no custom buttons — OK only dismisses it.
        @CasePathable
        enum Alert: Equatable {}

        @CasePathable
        enum View {

            /// Opens the "add result" editor for this movement.
            case addEntryTapped

            /// Asks to delete one history entry — shows the confirmation dialog.
            case deleteEntryTapped(PREntry)

            /// Switches the progress chart to one year's entries.
            case chartYearTapped(Int)
        }

        @CasePathable
        enum Dialog {

            /// User confirmed deleting the entry with this id.
            case confirmDelete(UUID)
        }
    }
}
