//
//  GroupFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GroupFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The group on screen.
        var group: TeamGroup

        /// Current account id — marks "You" in the member list.
        var myUid: String

        /// Name other members see, used for invites and entries.
        var displayName: String

        /// Members, earliest first.
        var members: [TeamMember] = []

        /// Loading state of the member list.
        var viewState: ViewState = .loading

        /// The group's plan for today; `nil` when none is published.
        var todayPlan: TeamPlan?

        /// Loading state of today's plan.
        var todayPlanState: ViewState = .loading

        /// Today's plan is already in the user's Plans.
        var isTodayPlanDownloaded = false

        /// Saving today's plan to Plans is in flight.
        var isDownloadingTodayPlan = false

        /// A leave request is in flight.
        var isLeaving = false

        // MARK: - Alert

        /// Confirmation before leaving, or the error after a failed attempt.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?

        // MARK: - Derived

        /// The current account created this group.
        var isOwner: Bool {
            group.ownerUid == myUid
        }
    }

}
