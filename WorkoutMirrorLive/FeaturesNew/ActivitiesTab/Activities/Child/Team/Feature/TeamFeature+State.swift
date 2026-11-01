//
//  TeamFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension TeamFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The color representing the training readiness level, shared with the other tabs.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// Selected top segment.
        var segment: TeamSegment = .private

        /// Groups the user belongs to, newest first.
        var groups: [TeamGroup] = []

        /// The user's manual order of group ids, top to bottom — a preference of this device.
        @Shared(.appStorage(.teamGroupOrder))
        var orderedGroupIds: [String] = []

        /// Scanned invites still waiting for a decision and still valid, newest first.
        var pendingInvitations: [TeamInvitation] = []

        /// Invitations whose join or decline is in flight.
        var respondingInvitationIds: Set<TeamInvitation.ID> = []

        /// Groups whose leave or delete is in flight.
        var workingGroupIds: Set<TeamGroup.ID> = []

        /// Today's day id, set when the groups arrive — picks which plan summaries count as today's.
        var today = ""

        /// The user's result for today's plan, by group id; groups without one are absent.
        var myEntries: [String: TeamEntry] = [:]

        /// Loading state of the private segment.
        var viewState: ViewState = .loading

        /// Account id once signed in; marks the user's own groups.
        var myUid: String?

        /// Name other members see, from the profile.
        var displayName: String = ""

        /// Set after the first appearance so returning to the tab keeps the running listener.
        var hasStarted = false

        // MARK: - Derived

        /// Groups the user has not placed yet (new ones) on top, newest first, then the saved order.
        var orderedGroups: [TeamGroup] {
            let placed = orderedGroupIds.compactMap { id in groups.first { $0.id == id } }
            let unplaced = groups.filter { !orderedGroupIds.contains($0.id) }
            return unplaced + placed
        }

        // MARK: - Alert

        /// Confirmation before declining an invitation.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }

}
