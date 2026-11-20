//
//  TeamSubmitFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension TeamSubmitFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — group, plan and any earlier entry were read.
        case loaded(TeamSubmitContext)

        /// Internal — reading failed (offline or no access).
        case loadFailed

        @CasePathable
        enum View {

            /// Called when the row appears.
            case viewDidAppear

            /// Called when the user switches sending on or off.
            case enabledChanged(Bool)

            /// Called when the user picks Rx or Scaled.
            case divisionChanged(BoardDivision)

            /// Called when the user switches kcal sharing.
            case includeKcalChanged(Bool)
        }
    }

}
