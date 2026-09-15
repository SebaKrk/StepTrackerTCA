//
//  PRMovementListFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

extension PRMovementListFeature {

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case detail(PresentationAction<PRMovementDetailFeature.Action>)

        @CasePathable
        enum View {
            case movementTapped(PRMovement)
        }
    }
}
