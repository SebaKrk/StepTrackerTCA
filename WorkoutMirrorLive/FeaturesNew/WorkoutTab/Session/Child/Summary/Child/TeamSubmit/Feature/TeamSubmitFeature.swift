//
//  TeamSubmitFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// "Send to group" row on the Summary of a workout done from a downloaded group plan.
/// It only collects the choice; `SummaryFeature` builds and sends the entry on save.
@Reducer
struct TeamSubmitFeature {

    @Dependency(\.teamClient) var teamClient
    @Dependency(\.userProfileClient) var userProfileClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.viewDidAppear):
                guard state.context == nil else { return .none }
                return .run { [groupId = state.groupId, day = state.day, teamClient, userProfileClient] send in
                    let uid = try await teamClient.ensureSignedIn()
                    let profile = try? await userProfileClient.fetch()
                    async let group = teamClient.group(groupId)
                    async let plan = teamClient.plan(groupId, day)
                    async let entry = teamClient.myEntry(groupId, day)
                    await send(.loaded(TeamSubmitContext(
                        uid: uid,
                        displayName: TeamDisplayName.make(nickname: profile?.nickname, name: profile?.name, uid: uid),
                        groupName: try await group?.name,
                        plan: try await plan,
                        existingEntry: try await entry
                    )))
                } catch: { error, send in
                    Logger.team.error("Team submit context failed: \(error.localizedDescription)")
                    await send(.loadFailed)
                }

            case let .view(.enabledChanged(isEnabled)):
                state.isEnabled = isEnabled
                return .none

            case let .view(.divisionChanged(division)):
                state.division = division
                return .none

            case let .view(.includeKcalChanged(include)):
                state.$includeKcal.withLock { $0 = include }
                return .none

            case let .loaded(context):
                state.context = context
                state.loadState = context.plan == nil ? .failed : .success
                if let earlier = context.existingEntry {
                    state.division = earlier.division
                }
                return .none

            case .loadFailed:
                state.loadState = .failed
                return .none
            }
        }
    }
}
