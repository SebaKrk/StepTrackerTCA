//
//  PublishPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

extension PublishPlanFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Group the plan is published to.
        var groupId: String

        /// Current account id — the author.
        var myUid: String

        /// Author name shown to the group.
        var displayName: String

        /// Accent of the Team tab — background gradient and the publish button.
        var color: Color

        /// The user's plans from Plans, newest first.
        var plans: [TrainingSession] = []

        /// Plan opened from the list, with any minutes filled in by "Fill to 60 min"; `nil` shows the list.
        var selectedPlan: TrainingSession?

        /// Block whose score builds the leaderboard.
        var scoredBlockId: UUID?

        /// Loading state of the plan list.
        var viewState: ViewState = .loading

        /// Publishing is in flight.
        var isPublishing = false

        /// Message of the last failed attempt.
        var errorMessage: String?

        /// UI-only — warm-up card expanded in the plan detail.
        var isWarmupExpanded = true

        /// UI-only — cool-down card expanded in the plan detail.
        var isCooldownExpanded = true

        // MARK: - Derived

        /// Class length of the selected plan.
        var plannedTotalMinutes: Int {
            selectedPlan?.plannedTotalMinutes ?? 0
        }

        /// Minutes missing to the 60-minute class.
        var missingMinutes: Int {
            selectedPlan?.missingPlannedMinutes(target: Self.classMinutes) ?? Self.classMinutes
        }

        /// Publish is allowed for a plan of at least 60 minutes with a scored block.
        var canPublish: Bool {
            selectedPlan != nil && scoredBlockId != nil && missingMinutes == 0 && !isPublishing
        }

        /// Shortest plan a group accepts — the server rule checks the same number.
        static let classMinutes = 60
    }

}
