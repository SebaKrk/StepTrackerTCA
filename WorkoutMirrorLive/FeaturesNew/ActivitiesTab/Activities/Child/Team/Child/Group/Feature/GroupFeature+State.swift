//
//  GroupFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

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

        /// Accent of the Team tab — background gradient and prominent controls.
        var color: Color

        /// Members, earliest first.
        var members: [TeamMember] = []

        /// Loading state of the member list.
        var viewState: ViewState = .loading

        /// Today's day id — the latest day the navigator reaches.
        var today = ""

        /// Day on screen; the plan card and the day ranking follow it.
        var selectedDay = ""

        /// Monday…Sunday of the selected day's week.
        var weekDays: [GroupDay] = []

        /// The group's plan of the selected day; `nil` when none was published.
        var dayPlan: TeamPlan?

        /// Loading state of the selected day's plan.
        var dayPlanState: ViewState = .loading

        /// The selected day's plan is already in the user's Plans.
        var isDayPlanDownloaded = false

        /// When the local copy of the selected day's plan was taken; `nil` without a copy.
        var dayPlanDownloadedAt: Date?

        /// The counters on the group document were already repaired on this screen.
        var hasSyncedCounters = false

        /// Saving the selected day's plan to Plans is in flight.
        var isDownloadingDayPlan = false

        /// Leaderboard section (today and the week).
        var leaderboard: GroupLeaderboardFeature.State

        /// A leave request is in flight.
        var isLeaving = false

        /// Deleting today's plan is in flight.
        var isDeletingDayPlan = false

        /// The plan preview sheet is closing after "Start Workout"; the session waits for its `onDismiss`.
        var isPreviewClosing = false

        /// Workout that arrived while the preview sheet was still closing.
        var pendingWorkout: GroupPendingWorkout?

        // MARK: - Alert

        /// Confirmation before leaving, or the error after a failed attempt.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?

        // MARK: - Init

        init(group: TeamGroup, myUid: String, displayName: String, color: Color) {
            self.group = group
            self.myUid = myUid
            self.displayName = displayName
            self.color = color
            self.leaderboard = GroupLeaderboardFeature.State(groupId: group.id, myUid: myUid)
        }

        // MARK: - Derived

        /// The current account created this group.
        var isOwner: Bool {
            group.ownerUid == myUid
        }

        /// Downloading and publishing work only for today — the points window runs from the workout start.
        var isSelectedDayToday: Bool {
            selectedDay == today
        }

        /// Who inherits the group if the owner leaves: the longest-standing other member (members arrive sorted by join date).
        var successor: TeamMember? {
            members.first { $0.uid != myUid }
        }

        /// The author republished the plan after the user downloaded it, so the copy in Plans is behind.
        var isDayPlanStale: Bool {
            guard let plan = dayPlan, let downloadedAt = dayPlanDownloadedAt else { return false }
            return plan.publishedAt > downloadedAt
        }

        /// Only the owner removes a plan, and only today's — past days are history.
        var canDeleteDayPlan: Bool {
            isOwner && isSelectedDayToday && dayPlan != nil && !isDeletingDayPlan
        }

        /// Leaving needs the member list: the alert names the successor from it.
        var canLeave: Bool {
            viewState == .success && !isLeaving
        }

        /// Results of today's plan are known, so an empty board really is empty.
        var isDayBoardKnownEmpty: Bool {
            leaderboard.isDayLoaded && leaderboard.dayEntries.isEmpty
        }

        /// The selected day as a date; `nil` before the first appearance.
        var selectedDate: Date? {
            weekDays.first { $0.id == selectedDay }?.date
        }

        /// Days of the shown week that have a plan — dots of the week strip.
        var daysWithPlan: Set<String> {
            var days = Set(leaderboard.weekEntries?.keys.map { $0 } ?? [])
            if dayPlan != nil {
                days.insert(selectedDay)
            }
            return days
        }
    }

}
