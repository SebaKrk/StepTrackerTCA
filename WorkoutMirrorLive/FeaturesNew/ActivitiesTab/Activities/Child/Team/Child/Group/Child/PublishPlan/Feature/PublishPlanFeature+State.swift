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

        /// Plan opened from the list, published exactly as it is; `nil` shows the list.
        var selectedPlan: TrainingSession?

        /// Blocks whose results the leaderboard shows; may be empty — points rank everyone anyway.
        var scoredBlockIds: Set<UUID> = []

        /// Effort points window from each member's start — the same for the whole group.
        var effortWindowMinutes = Self.defaultEffortWindowMinutes

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

        /// Publish is allowed for any selected plan.
        var canPublish: Bool {
            selectedPlan != nil && !isPublishing
        }

        /// Window offered when a plan is opened.
        static let defaultEffortWindowMinutes = 60

        /// Allowed windows — the server rule rejects anything under 60 minutes.
        static let effortWindowRange = 60...120

        /// Stepper step of the window.
        static let effortWindowStep = 5
    }

}
