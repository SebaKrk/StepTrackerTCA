//
//  GroupLeaderboardFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GroupLeaderboardFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Group on screen.
        let groupId: String

        /// Current account id — highlights the user's row.
        let myUid: String

        /// Today or the whole week.
        var range: TeamLeaderboardRange = .day

        /// Rank by score or by effort.
        var lens: TeamLeaderboardLens = .score

        /// Rx or Scaled.
        var division: BoardDivision = .rx

        /// The user picked a division; until then it follows the user's own entry.
        var hasPickedDivision = false

        /// Length of today's plan — measurement window for the coverage badge; `nil` without a plan.
        var planMinutes: Int?

        /// Today's day id.
        var today: String = ""

        /// Monday…Sunday ids of the current week.
        var weekDays: [String] = []

        /// Entries of today's plan, as they arrive.
        var dayEntries: [TeamEntry] = []

        /// Entries per day with a plan this week; `nil` until loaded.
        var weekEntries: [String: [TeamEntry]]?

        /// Ranked rows of today for the current lens and division.
        var dayRows: [TeamLeaderboardRow] = []

        /// Week table for the current lens and division.
        var weekRows: [TeamWeekRow] = []

        /// Loading state of the selected range.
        var viewState: ViewState = .loading

        init(groupId: String, myUid: String) {
            self.groupId = groupId
            self.myUid = myUid
        }
    }

}
