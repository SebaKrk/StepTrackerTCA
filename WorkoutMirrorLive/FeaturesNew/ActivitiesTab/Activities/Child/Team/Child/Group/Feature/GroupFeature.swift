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
                    !state.isDayPlanDownloaded,
                    !state.isDownloadingDayPlan
                else { return .none }
                state.isDownloadingDayPlan = true
                let copy = plan.session.downloadedTeamCopy(
                    id: uuid(),
                    date: date.now,
                    teamPlanId: TrainingSession.teamPlanId(groupId: state.group.id, day: plan.id)
                )
                return .run { [trainingSessionClient] send in
                    try await trainingSessionClient.save(copy)
                    await send(.dayPlanDownloadFinished(true))
                } catch: { error, send in
                    Logger.team.error("Download plan failed: \(error.localizedDescription)")
                    await send(.dayPlanDownloadFinished(false))
                }

            case .view(.leaveTapped):
                state.alert = Self.leaveConfirmation(isOwner: state.isOwner)
                return .none

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

            case .view(.inviteTapped):
                state.destination = .invite(
                    InviteFeature.State(group: state.group, displayName: state.displayName, color: state.color)
                )
                return .none

            // MARK: - Internal

            case let .membersLoaded(members):
                state.members = members
                state.viewState = .success
                return .none

            case .membersFailed:
                state.viewState = .failed
                return .none

            case let .dayPlanLoaded(plan, isDownloaded):
                state.dayPlan = plan
                state.isDayPlanDownloaded = isDownloaded
                state.dayPlanState = .success
                return .send(.leaderboard(.planChanged(plan)))

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

            case .alert(.presented(.confirmLeave)):
                state.isLeaving = true
                return .run { [groupId = state.group.id, teamClient] send in
                    try await teamClient.leaveGroup(groupId)
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
                state.alert = AlertState {
                    TextState(String(localized: "Couldn't Leave the Group"))
                } message: {
                    TextState(message)
                }
                return .none

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

    private func listenToDayPlan(groupId: String, day: String) -> Effect<Action> {
        .run { [teamClient, trainingSessionClient] send in
            let teamPlanId = TrainingSession.teamPlanId(groupId: groupId, day: day)
            for try await plan in teamClient.observePlan(groupId, day) {
                let copy = plan == nil ? nil : try await trainingSessionClient.fetchByTeamPlanId(teamPlanId)
                await send(.dayPlanLoaded(plan, isDownloaded: copy != nil))
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

    // The owner leaving does not delete the group — the others keep training in it.
    private static func leaveConfirmation(isOwner: Bool) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "Leave Group?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmLeave) {
                TextState(String(localized: "Leave"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(
                isOwner
                    ? String(localized: "You created this group. It stays for the other members; you can come back only with a new invite.")
                    : String(localized: "You can come back only with a new invite.")
            )
        }
    }
}
