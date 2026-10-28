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
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                return .merge(loadMembers(groupId: state.group.id), loadTodayPlan(groupId: state.group.id))

            case .view(.todayPlanPreviewTapped):
                guard let plan = state.todayPlan else { return .none }
                state.destination = .planPreview(
                    PlanPreviewFeature.State(groupId: state.group.id, plan: plan, isDownloaded: state.isTodayPlanDownloaded)
                )
                return .none

            case .view(.todayPlanDownloadTapped):
                guard let plan = state.todayPlan, !state.isTodayPlanDownloaded, !state.isDownloadingTodayPlan else {
                    return .none
                }
                state.isDownloadingTodayPlan = true
                let copy = plan.session.downloadedTeamCopy(
                    id: uuid(),
                    date: date.now,
                    teamPlanId: TrainingSession.teamPlanId(groupId: state.group.id, day: plan.id)
                )
                return .run { [trainingSessionClient] send in
                    try await trainingSessionClient.save(copy)
                    await send(.todayPlanDownloadFinished(true))
                } catch: { error, send in
                    Logger.team.error("Download plan failed: \(error.localizedDescription)")
                    await send(.todayPlanDownloadFinished(false))
                }

            case .view(.leaveTapped):
                state.alert = Self.leaveConfirmation(isOwner: state.isOwner)
                return .none

            case .view(.publishPlanTapped):
                state.destination = .publishPlan(
                    PublishPlanFeature.State(groupId: state.group.id, myUid: state.myUid, displayName: state.displayName)
                )
                return .none

            case .view(.inviteTapped):
                state.destination = .invite(
                    InviteFeature.State(group: state.group, displayName: state.displayName)
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

            case let .todayPlanLoaded(plan, isDownloaded):
                state.todayPlan = plan
                state.isTodayPlanDownloaded = isDownloaded
                state.todayPlanState = .success
                return .none

            case .todayPlanFailed:
                state.todayPlanState = .failed
                return .none

            case let .todayPlanDownloadFinished(saved):
                state.isDownloadingTodayPlan = false
                if saved {
                    state.isTodayPlanDownloaded = true
                }
                return .none

            case .destination(.presented(.publishPlan(.delegate(.published)))):
                state.todayPlanState = .loading
                return loadTodayPlan(groupId: state.group.id)

            case .destination(.presented(.planPreview(.delegate(.downloaded)))):
                state.isTodayPlanDownloaded = true
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

            case .alert, .delegate, .destination:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    private func loadTodayPlan(groupId: String) -> Effect<Action> {
        let day = TeamDay.id(for: date.now, calendar: calendar)
        return .run { [teamClient, trainingSessionClient] send in
            let plan = try await teamClient.plan(groupId, day)
            let teamPlanId = TrainingSession.teamPlanId(groupId: groupId, day: day)
            let copy = plan == nil ? nil : try await trainingSessionClient.fetchByTeamPlanId(teamPlanId)
            await send(.todayPlanLoaded(plan, isDownloaded: copy != nil))
        } catch: { error, send in
            Logger.team.error("Today's plan failed: \(error.localizedDescription)")
            await send(.todayPlanFailed)
        }
    }

    private func loadMembers(groupId: String) -> Effect<Action> {
        .run { [teamClient] send in
            await send(.membersLoaded(try await teamClient.members(groupId)))
        } catch: { error, send in
            Logger.team.error("Members failed: \(error.localizedDescription)")
            await send(.membersFailed)
        }
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
