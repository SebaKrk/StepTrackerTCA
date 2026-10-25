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

            case let .view(.scoredBlockSelected(id)):
                state.scoredBlockId = id
                return .none

            case .view(.fillClassLengthTapped):
                state.selectedPlan = state.selectedPlan?.fillingClassLength(to: State.classMinutes)
                return .none

            case .view(.publishTapped):
                guard state.canPublish, let session = state.selectedPlan, let scoredBlockId = state.scoredBlockId else {
                    return .none
                }
                state.isPublishing = true
                state.errorMessage = nil
                let now = date.now
                let plan = TeamPlan(
                    id: TeamDay.id(for: now, calendar: calendar),
                    authorUid: state.myUid,
                    authorName: state.displayName,
                    session: session,
                    scoredBlockId: scoredBlockId,
                    sessionMinutes: session.plannedTotalMinutes,
                    publishedAt: now
                )
                return .run { [groupId = state.groupId, myUid = state.myUid, teamClient] send in
                    // One plan per day: only its author may replace it.
                    if let existing = try await teamClient.plan(groupId, plan.id), existing.authorUid != myUid {
                        await send(.publishFailed(
                            String(localized: "Today's plan was already published by \(existing.authorName).")
                        ))
                        return
                    }
                    try await teamClient.publishPlan(groupId, plan)
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
                if let first = plans.first {
                    select(&state, planId: first.id)
                }
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

            case .delegate:
                return .none
            }
        }
    }

    private func select(_ state: inout State, planId: UUID) {
        state.selectedPlan = state.plans.first { $0.id == planId }
        state.scoredBlockId = state.selectedPlan?.defaultScoredBlockId
        state.errorMessage = nil
    }
}
