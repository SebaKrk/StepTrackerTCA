//
//  GroupLeaderboardFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GroupLeaderboardFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — today's entries changed.
        case dayEntriesUpdated([TeamEntry])

        /// Internal — the week's entries were read.
        case weekLoaded([String: [TeamEntry]])

        /// Internal — reading failed.
        case failed

        @CasePathable
        enum View {

            /// Called when the section appears.
            case viewDidAppear

            /// Called when the user switches Today / Week.
            case rangeChanged(TeamLeaderboardRange)

            /// Called when the user switches Score / Effort.
            case lensChanged(TeamLeaderboardLens)

            /// Called when the user switches Rx / Scaled.
            case divisionChanged(BoardDivision)
        }
    }

}
