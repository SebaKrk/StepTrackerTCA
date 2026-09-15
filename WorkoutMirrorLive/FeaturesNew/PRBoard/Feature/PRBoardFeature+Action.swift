//
//  PRBoardFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

extension PRBoardFeature {

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case movementList(PresentationAction<PRMovementListFeature.Action>)

        @CasePathable
        enum View {
            case categoryTapped(PRCategory)
            case closeTapped
        }
    }
}
