//
//  PublishPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct PublishPlanFeature {

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.teamClient) var teamClient
    @Dependency(\.trainingSessionClient) var trainingSessionClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                guard state.plans.isEmpty else { return .none }
                return .run { [trainingSessionClient] send in
                    await send(.plansLoaded(try await trainingSessionClient.fetchAll()))
                } catch: { error, send in
                    Logger.team.error("Publish — plans failed: \(error.localizedDescription)")
                    await send(.plansFailed)
                }

            case let .view(.planSelected(id)):
                select(&state, planId: id)
                return .none

            case .view(.planDetailClosed):
                state.selectedPlan = nil
                state.scoredBlockIds = []
                state.errorMessage = nil
                return .none

            case let .view(.scoredBlockToggled(id, isOn)):
                guard
                    let block = state.selectedPlan?.workouts.first(where: { $0.id == id }),
                    block.type.boardScoreKind.isScored
                else { return .none }
                if isOn {
                    state.scoredBlockIds.insert(id)
                } else {
                    state.scoredBlockIds.remove(id)
                }
                return .none

            case let .view(.effortWindowChanged(minutes)):
                let range = State.effortWindowRange
                state.effortWindowMinutes = min(max(minutes, range.lowerBound), range.upperBound)
                return .none

            case .view(.publishTapped):
                guard state.canPublish, let session = state.selectedPlan else { return .none }
                state.isPublishing = true
                state.errorMessage = nil
                let now = date.now
                let plan = TeamPlan(
                    id: TeamDay.id(for: now, calendar: calendar),
                    authorUid: state.myUid,
                    authorName: state.displayName,
                    session: session,
                    scoredBlockIds: session.workouts.map(\.id).filter(state.scoredBlockIds.contains),
                    sessionMinutes: state.effortWindowMinutes,
                    publishedAt: now
                )
                return .run { [groupId = state.groupId, myUid = state.myUid, teamClient, trainingSessionClient] send in
                    // One plan per day: only its author may replace it.
                    if let existing = try await teamClient.plan(groupId, plan.id), existing.authorUid != myUid {
                        await send(.publishFailed(
                            String(localized: "Today's plan was already published by \(existing.authorName).")
                        ))
                        return
                    }
                    try await teamClient.publishPlan(groupId, plan)
                    // The author's own plan becomes the group copy, so the group never offers a second download.
                    try await trainingSessionClient.save(
                        session.linkedToTeamPlan(TrainingSession.teamPlanId(groupId: groupId, day: plan.id))
                    )
                    await send(.published(plan))
                } catch: { error, send in
                    Logger.team.error("Publish failed: \(error.localizedDescription)")
                    await send(.publishFailed(error.localizedDescription))
                }

            case .view(.cancelTapped):
                return .run { [dismiss] _ in await dismiss() }

            // MARK: - Internal

            case let .plansLoaded(plans):
                state.plans = plans
                state.viewState = .success
                return .none

            case .plansFailed:
                state.viewState = .failed
                return .none

            case let .published(plan):
                state.isPublishing = false
                return .run { [dismiss] send in
                    await send(.delegate(.published(plan)))
                    await dismiss()
                }

            case let .publishFailed(message):
                state.isPublishing = false
                state.errorMessage = message
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }

    private func select(_ state: inout State, planId: UUID) {
        state.selectedPlan = state.plans.first { $0.id == planId }
        state.scoredBlockIds = Set(state.selectedPlan?.defaultScoredBlockIds ?? [])
        state.effortWindowMinutes = State.defaultEffortWindowMinutes
        state.errorMessage = nil
    }
}
