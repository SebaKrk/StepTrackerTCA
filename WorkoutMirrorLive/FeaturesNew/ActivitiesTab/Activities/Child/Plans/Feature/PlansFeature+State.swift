//
//  PlansFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension PlansFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The tier the whole app reads; Basic opens only the most recent plans.
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        /// Training session plans loaded from SQLite.
        var sessions: [TrainingSession] = []

        /// Plans Basic may open: the most recent few.
        var openSessionIDs: Set<UUID> = []

        /// Whether opening this plan needs Pro.
        func isLocked(_ session: TrainingSession) -> Bool {
            subscriptionTier == .basic && !openSessionIDs.contains(session.id)
        }

        /// Plans the current tier opens.
        var unlockedSessions: [TrainingSession] {
            sessions.filter { !isLocked($0) }
        }

        /// Plans that need Pro; shown blurred under the banner.
        var lockedSessions: [TrainingSession] {
            sessions.filter { isLocked($0) }
        }

        /// Current view state.
        var viewState: ViewState = .loading

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?

        // MARK: - Scrolling

        /// Whether the list sits away from its top.
        ///
        /// Tracked so a tab-bar tap scrolls back before it does anything else,
        /// which is the order iOS uses.
        var isScrolled: Bool = false

        /// Bumped to ask the list to scroll back to the top.
        ///
        /// A counter rather than a flag: two taps in a row must both land, and
        /// a flag set to `true` twice is a single change to the view.
        var scrollToTopToken: Int = 0
    }

}
