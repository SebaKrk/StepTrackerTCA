//
//  GroupFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct GroupFeature {

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.teamClient) var teamClient
    @Dependency(\.trainingSessionClient) var trainingSessionClient
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        Scope(state: \.leaderboard, action: \.leaderboard) {
            GroupLeaderboardFeature()
        }
        Reduce { state, action in
            switch action {

            // MARK: - View

            // Restarted on every appearance, so returning from Plans re-checks the local copy and the week too.
            case .view(.viewDidAppear):
                state.today = TeamDay.id(for: date.now, calendar: calendar)
                let day = state.selectedDay.isEmpty ? state.today : state.selectedDay
                return .merge(
                    listenToMembers(groupId: state.group.id),
                    show(day: day, state: &state, reloadWeek: true)
                )

            case .view(.previousDayTapped):
                return shiftDay(by: -1, state: &state)

            case .view(.nextDayTapped):
                return shiftDay(by: 1, state: &state)

            case let .view(.daySelected(day)):
                guard day != state.selectedDay, day <= state.today else { return .none }
                return show(day: day, state: &state, reloadWeek: false)

            case .view(.dayPlanPreviewTapped):
                guard let plan = state.dayPlan else { return .none }
                state.destination = .planPreview(
                    PlanPreviewFeature.State(
                        groupId: state.group.id,
                        plan: plan,
                        isDownloaded: state.isDayPlanDownloaded,
                        canDownload: state.isSelectedDayToday,
                        color: state.color
                    )
                )
                return .none

            case .view(.dayPlanDownloadTapped):
                guard
                    state.isSelectedDayToday,
                    let plan = state.dayPlan,
                    !state.isDayPlanDownloaded || state.isDayPlanStale,
                    !state.isDownloadingDayPlan
                else { return .none }
                state.isDownloadingDayPlan = true
                let copy = teamCopy(of: plan, groupId: state.group.id)
                let teamPlanId = TrainingSession.teamPlanId(groupId: state.group.id, day: plan.id)
                return .run { [trainingSessionClient] send in
                    // A republished plan replaces the copy instead of adding a second one under the same link.
                    if let stale = try await trainingSessionClient.fetchByTeamPlanId(teamPlanId) {
                        try await trainingSessionClient.delete(stale.id)
                    }
                    try await trainingSessionClient.save(copy)
                    await send(.dayPlanDownloadFinished(true))
                } catch: { error, send in
                    Logger.team.error("Download plan failed: \(error.localizedDescription)")
                    await send(.dayPlanDownloadFinished(false))
                }

            case .view(.leaveTapped):
                guard state.canLeave else { return .none }
                state.alert = .leave(isOwner: state.isOwner, successor: state.successor)
                return .none

            case .view(.deletePlanTapped):
                guard state.canDeleteDayPlan else { return .none }
                // Results already posted deserve a second look; only a board known to be empty goes right away.
                if state.isDayBoardKnownEmpty {
                    return deleteDayPlan(state: &state)
                }
                state.alert = .deletePlan()
                return .none

            case .view(.previewDismissed):
                state.isPreviewClosing = false
                guard let pending = state.pendingWorkout else { return .none }
                state.pendingWorkout = nil
                return .send(.workoutReady(pending.plan, pending.device))

            case .view(.publishPlanTapped):
                guard state.isSelectedDayToday else { return .none }
                state.destination = .publishPlan(
                    PublishPlanFeature.State(
                        groupId: state.group.id,
                        myUid: state.myUid,
                        displayName: state.displayName,
                        color: state.color
                    )
                )
                return .none

            case .view(.manageTapped):
                guard state.isOwner else { return .none }
                state.destination = .manage(
                    ManageGroupFeature.State(group: state.group, myUid: state.myUid, color: state.color)
                )
                return .none

            case .view(.inviteTapped):
                state.destination = .invite(
                    InviteFeature.State(group: state.group, displayName: state.displayName, color: state.color)
                )
                return .none

            // MARK: - Internal

            case let .membersLoaded(members):
                state.members = members
                state.viewState = .success
                return syncCountersIfNeeded(&state)

            case .membersFailed:
                state.viewState = .failed
                return .none

            case let .dayPlanLoaded(plan, downloadedAt):
                state.dayPlan = plan
                state.dayPlanDownloadedAt = downloadedAt
                state.isDayPlanDownloaded = downloadedAt != nil
                state.dayPlanState = .success
                return .merge(
                    .send(.leaderboard(.planChanged(plan))),
                    syncCountersIfNeeded(&state)
                )

            case .dayPlanFailed:
                state.dayPlanState = .failed
                return .none

            case let .dayPlanDownloadFinished(saved):
                state.isDownloadingDayPlan = false
                if saved {
                    state.isDayPlanDownloaded = true
                }
                return .none

            case .destination(.presented(.planPreview(.delegate(.downloaded)))),
                 .destination(.presented(.publishPlan(.delegate(.published)))):
                state.isDayPlanDownloaded = true
                return .none

            case let .destination(.presented(.manage(.delegate(.groupChanged(group))))):
                state.group = group
                return .none

            case .destination(.presented(.manage(.delegate(.deleted)))):
                return .run { [dismiss] send in
                    await send(.delegate(.left))
                    await dismiss()
                }

            // The sheet closes first; the session is presented only after its onDismiss, whichever
            // arrives later — the copy from the database or the end of the dismiss animation.
            case .destination(.presented(.planPreview(.delegate(.startWorkout(let device))))):
                guard state.isSelectedDayToday, let plan = state.dayPlan else { return .none }
                state.destination = nil
                state.isPreviewClosing = true
                return loadWorkoutCopy(plan: plan, groupId: state.group.id, device: device)

            case let .workoutReady(copy, device):
                guard !state.isPreviewClosing else {
                    state.pendingWorkout = GroupPendingWorkout(plan: copy, device: device)
                    return .none
                }
                let workout = WorkoutType(hkType: copy.activity.hkType) ?? .cross
                state.destination = .session(
                    SessionFeature.State(
                        selectedWorkout: workout,
                        requestedDevice: device,
                        trainingSession: copy,
                        countDown: CountDownFeature.State(workoutType: copy.activity)
                    )
                )
                return .none

            case let .workoutStartFailed(message):
                state.alert = .workoutStartFailed(message)
                return .none

            case .alert(.presented(.confirmDeletePlan)):
                return deleteDayPlan(state: &state)

            case .planDeleted:
                state.isDeletingDayPlan = false
                return .none

            case let .deletePlanFailed(message):
                state.isDeletingDayPlan = false
                state.alert = .deletePlanFailed(message)
                return .none

            case .alert(.presented(.confirmLeave)):
                state.isLeaving = true
                return .run { [groupId = state.group.id, successorUid = state.successor?.uid, teamClient] send in
                    try await teamClient.leaveGroup(groupId, successorUid)
                    await send(.left)
                } catch: { error, send in
                    Logger.team.error("Leave group failed: \(error.localizedDescription)")
                    await send(.leaveFailed(error.localizedDescription))
                }

            case .left:
                state.isLeaving = false
                return .run { [dismiss] send in
                    await send(.delegate(.left))
                    await dismiss()
                }

            case let .leaveFailed(message):
                state.isLeaving = false
                state.alert = .leaveFailed(message)
                return .none

            case .leaderboard(.dayEntriesUpdated):
                return syncCountersIfNeeded(&state)

            case .alert, .delegate, .destination, .leaderboard:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    // Plan and ranking switch together, so the card and the table never show different days.
    private func show(day: String, state: inout State, reloadWeek: Bool) -> Effect<Action> {
        guard let date = TeamDay.date(for: day, calendar: calendar) else { return .none }
        if day != state.selectedDay {
            state.selectedDay = day
            state.dayPlan = nil
            state.dayPlanState = .loading
            state.isDayPlanDownloaded = false
            state.isDownloadingDayPlan = false
        }
        state.weekDays = TeamDay.weekIds(containing: date, calendar: calendar).compactMap { id in
            TeamDay.date(for: id, calendar: calendar).map { GroupDay(id: id, date: $0) }
        }
        return .merge(
            listenToDayPlan(groupId: state.group.id, day: day),
            .send(.leaderboard(.showDay(day, weekDays: state.weekDays.map(\.id), reloadWeek: reloadWeek)))
        )
    }

    private func shiftDay(by offset: Int, state: inout State) -> Effect<Action> {
        guard
            let selected = state.selectedDate,
            let target = calendar.date(byAdding: .day, value: offset, to: selected)
        else { return .none }
        // Day ids are `yyyy-MM-dd`, so string order is date order.
        let day = TeamDay.id(for: target, calendar: calendar)
        guard day <= state.today else { return .none }
        return show(day: day, state: &state, reloadWeek: false)
    }

    /// The user's own copy of a group plan — what Plans stores and the Summary posts from.
    private func teamCopy(of plan: TeamPlan, groupId: String) -> TrainingSession {
        plan.session.downloadedTeamCopy(
            id: uuid(),
            date: date.now,
            teamPlanId: TrainingSession.teamPlanId(groupId: groupId, day: plan.id)
        )
    }

    // The session runs on the copy in Plans; the start button only shows once it exists.
    private func loadWorkoutCopy(plan: TeamPlan, groupId: String, device: DeviceOption) -> Effect<Action> {
        let teamPlanId = TrainingSession.teamPlanId(groupId: groupId, day: plan.id)
        return .run { [trainingSessionClient] send in
            guard let copy = try await trainingSessionClient.fetchByTeamPlanId(teamPlanId) else {
                await send(.workoutStartFailed(String(localized: "Download the plan to Plans first.")))
                return
            }
            await send(.workoutReady(copy, device))
        } catch: { error, send in
            Logger.team.error("Start workout failed: \(error.localizedDescription)")
            await send(.workoutStartFailed(error.localizedDescription))
        }
    }

    // Counters live on the group document and can drift: an older build, a failed batch, a result sent
    // offline. Once everything this screen needs is loaded, any member writes back what they can see.
    // Runs at most once per visit — the group in state is a snapshot and would otherwise never match.
    private func syncCountersIfNeeded(_ state: inout State) -> Effect<Action> {
        guard
            !state.hasSyncedCounters,
            state.viewState == .success,
            state.isSelectedDayToday,
            state.leaderboard.isDayLoaded
        else { return .none }
        state.hasSyncedCounters = true
        let memberCount = state.members.count == state.group.memberCount ? nil : state.members.count
        let summary = state.dayPlan.map { plan in
            TeamGroupPlanSummary(
                day: plan.id,
                title: plan.session.title,
                sessionMinutes: plan.sessionMinutes,
                authorName: plan.authorName,
                entryCount: state.leaderboard.dayEntries.count
            )
        }
        let lastPlan = summary == state.group.lastPlan ? nil : summary
        guard memberCount != nil || lastPlan != nil else { return .none }
        return .run { [groupId = state.group.id, teamClient] _ in
            try await teamClient.syncCounters(groupId, memberCount, lastPlan)
        } catch: { error, _ in
            Logger.team.error("Counter sync failed: \(error.localizedDescription)")
        }
    }

    // The plan and entry listeners clear the card and the board on their own once the delete lands.
    private func deleteDayPlan(state: inout State) -> Effect<Action> {
        guard state.canDeleteDayPlan else { return .none }
        state.isDeletingDayPlan = true
        return .run { [groupId = state.group.id, day = state.selectedDay, teamClient] send in
            try await teamClient.deletePlan(groupId, day)
            await send(.planDeleted)
        } catch: { error, send in
            Logger.team.error("Delete plan failed: \(error.localizedDescription)")
            await send(.deletePlanFailed(error.localizedDescription))
        }
    }

    private func listenToDayPlan(groupId: String, day: String) -> Effect<Action> {
        .run { [teamClient, trainingSessionClient] send in
            let teamPlanId = TrainingSession.teamPlanId(groupId: groupId, day: day)
            for try await plan in teamClient.observePlan(groupId, day) {
                let copy = plan == nil ? nil : try await trainingSessionClient.fetchByTeamPlanId(teamPlanId)
                await send(.dayPlanLoaded(plan, downloadedAt: copy?.date))
            }
        } catch: { error, send in
            Logger.team.error("Day plan failed: \(error.localizedDescription)")
            await send(.dayPlanFailed)
        }
        .cancellable(id: GroupCancelID.dayPlan, cancelInFlight: true)
    }

    private func listenToMembers(groupId: String) -> Effect<Action> {
        .run { [teamClient] send in
            for try await members in teamClient.observeMembers(groupId) {
                await send(.membersLoaded(members))
            }
        } catch: { error, send in
            Logger.team.error("Members failed: \(error.localizedDescription)")
            await send(.membersFailed)
        }
        .cancellable(id: GroupCancelID.members, cancelInFlight: true)
    }

}
