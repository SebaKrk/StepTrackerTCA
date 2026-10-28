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

        /// Sent by the group screen — shows `day`; the week is read again when it changed or `reloadWeek` is set.
        case showDay(String, weekDays: [String], reloadWeek: Bool)

        /// Sent by the group screen — the shown day's plan changed; `nil` without a plan.
        case planChanged(TeamPlan?)

        /// Internal — the shown day's entries changed.
        case dayEntriesUpdated([TeamEntry])

        /// Internal — the week's entries were read.
        case weekLoaded([String: [TeamEntry]])

        /// Internal — reading failed.
        case failed

        @CasePathable
        enum View {

            /// Called when the user switches Day / Week.
            case rangeChanged(TeamLeaderboardRange)

            /// Called when the user picks the ranking: `nil` for effort points, a block id for that block's result.
            case rankingSelected(UUID?)

            /// Called when the user switches Rx / Scaled.
            case divisionChanged(BoardDivision)
        }
    }

}
