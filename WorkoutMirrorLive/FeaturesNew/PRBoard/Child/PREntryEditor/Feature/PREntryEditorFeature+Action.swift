//
//  PREntryEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import SharedModels

extension PREntryEditorFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Two-way bindings of the draft fields (date, weight text, pickers, note).
        case binding(BindingAction<State>)

        /// Save effect failed — presents the save-failure alert; the sheet stays open.
        case saveFailed

        /// Presentation actions of the save-failure alert.
        case alert(PresentationAction<Alert>)

        /// Actions sent by the view.
        case view(View)

        /// Alert has no custom buttons — OK only dismisses it.
        @CasePathable
        enum Alert: Equatable {}

        @CasePathable
        enum View {

            /// Builds the entry (with a non-blocking body-weight snapshot), saves and dismisses.
            case saveTapped

            /// Dismisses the editor without saving.
            case cancelTapped

            /// Toggles one equipment item in the multi-select set.
            case equipmentToggled(PREquipment)
        }
    }
}
