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

        /// Actions sent by the view.
        case view(View)

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
