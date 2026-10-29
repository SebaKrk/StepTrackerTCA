//
//  TeamSubmitFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension TeamSubmitFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Group the downloaded plan came from.
        let groupId: String

        /// Day id of that group plan.
        let day: String

        /// Data read when the Summary opens; `nil` while loading.
        var context: TeamSubmitContext?

        /// Loading state of the context.
        var loadState: ViewState = .loading

        /// The user wants the result on the group leaderboard.
        var isEnabled = true

        /// Rx or Scaled.
        var division: BoardDivision = .rx

        /// Share active kcal with the group — health data, so off until the user turns it on once.
        @Shared(.appStorage("teamShareKcal")) var includeKcal = false

        // MARK: - Init

        /// `nil` for plans that did not come from a group.
        init?(teamPlanId: String?) {
            guard let teamPlanId, let parts = TrainingSession.teamPlanParts(teamPlanId) else { return nil }
            self.groupId = parts.groupId
            self.day = parts.day
        }

        // MARK: - Derived

        /// Ready to submit: switched on and the group plan is known.
        var willSubmit: Bool {
            isEnabled && context?.plan != nil
        }
    }

}
