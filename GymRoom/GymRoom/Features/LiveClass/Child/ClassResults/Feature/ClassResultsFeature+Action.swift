//
//  ClassResultsFeature+Action.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 09/07/2026.
//

import ComposableArchitecture

extension ClassResultsFeature {

    @CasePathable
    enum Action: BindableAction, ViewAction {

        /// `Table` sort-order binding (`$store.sortOrder`).
        case binding(BindingAction<State>)

        // MARK: - Delegate (parent — LiveClassFeature)

        /// Messages to the parent reducer.
        case delegate(Delegate)

        enum Delegate: Equatable {

            /// Trainer closed the results — the parent resumes the class-end
            /// flow (`delegate(.classEnded)` up to ClassesListFeature).
            case done
        }

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Tap "Done" in the toolbar.
            case doneTapped
        }
    }
}
