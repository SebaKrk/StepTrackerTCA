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

        /// The shown day or its whole week.
        var range: TeamLeaderboardRange = .day

        /// Rank by effort points (default) or by the scored block.
        var lens: TeamLeaderboardLens = .effort

        /// Rx or Scaled — splits the score ranking only.
        var division: BoardDivision = .rx

        /// The user picked a division; until then it follows the user's own entry.
        var hasPickedDivision = false

        /// Length of the shown day's plan — measurement window for the coverage badge; `nil` without a plan.
        var planMinutes: Int?

        /// Day id shown in the day ranking.
        var day: String = ""

        /// Monday…Sunday ids of the shown day's week.
        var weekDays: [String] = []

        /// Entries of the shown day's plan, as they arrive.
        var dayEntries: [TeamEntry] = []

        /// The first snapshot of the shown day's entries arrived.
        var isDayLoaded = false

        /// Entries per day with a plan this week; `nil` until loaded.
        var weekEntries: [String: [TeamEntry]]?

        /// Ranked rows of the shown day for the current lens and division.
        var dayRows: [TeamLeaderboardRow] = []

        /// Week table — points and kcal summed over the week.
        var weekRows: [TeamWeekRow] = []

        /// Loading state of the selected range.
        var viewState: ViewState = .loading

        init(groupId: String, myUid: String) {
            self.groupId = groupId
            self.myUid = myUid
        }
    }

}
