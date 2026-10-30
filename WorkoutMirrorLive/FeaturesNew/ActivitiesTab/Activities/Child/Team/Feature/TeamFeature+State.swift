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

        /// Groups the user belongs to, oldest first.
        var groups: [TeamGroup] = []

        /// Scanned invites still waiting for a decision and still valid, newest first.
        var pendingInvitations: [TeamInvitation] = []

        /// Invitations whose join or decline is in flight.
        var respondingInvitationIds: Set<TeamInvitation.ID> = []

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

        // MARK: - Alert

        /// Confirmation before declining an invitation.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }

}
