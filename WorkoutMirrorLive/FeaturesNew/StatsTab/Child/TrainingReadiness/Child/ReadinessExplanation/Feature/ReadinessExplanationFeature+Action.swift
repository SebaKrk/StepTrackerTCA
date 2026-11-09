//
//  ReadinessExplanationFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture

/// Implementation of `ReadinessExplanationFeature` action
extension ReadinessExplanationFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - View actions

        case view(View)

        enum View {

            /// Action triggered when the user closes the explanation.
            case closeButtonTapped
        }
    }

}
