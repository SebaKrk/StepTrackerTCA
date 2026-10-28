//
//  GroupLeaderboardFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// Leaderboard section of the group screen: the shown day's ranking and its week table.
@Reducer
struct GroupLeaderboardFeature {

    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // The week is always loaded: its plan days also feed the dots of the day navigator.
            case let .showDay(day, weekDays, reloadWeek):
                if reloadWeek || weekDays != state.weekDays {
                    state.weekDays = weekDays
                    state.weekEntries = nil
                }
                state.day = day
                state.dayEntries = []
                state.isDayLoaded = false
                recompute(&state)
                state.viewState = state.range == .week && state.weekEntries != nil ? .success : .loading
                return .merge(
                    listenToDay(groupId: state.groupId, day: day),
                    state.weekEntries == nil ? loadWeek(groupId: state.groupId, days: weekDays) : .none
                )

            case let .view(.rangeChanged(range)):
                state.range = range
                let isLoaded = range == .day ? state.isDayLoaded : state.weekEntries != nil
                state.viewState = isLoaded ? .success : .loading
                return .none

            case let .view(.rankingSelected(blockId)):
                if let blockId {
                    guard state.scoredBlocks.contains(where: { $0.id == blockId }) else { return .none }
                    state.lens = .score
                    state.selectedBlockId = blockId
                } else {
                    state.lens = .effort
                }
                recompute(&state)
                return .none

            case let .planChanged(plan):
                state.planMinutes = plan?.sessionMinutes
                state.scoredBlocks = plan?.scoredBlocks ?? []
                // Keep the picked block while it is still in the plan, so live updates don't reset the menu.
                if !state.scoredBlocks.contains(where: { $0.id == state.selectedBlockId }) {
                    state.selectedBlockId = state.scoredBlocks.first?.id
                }
                if state.scoredBlocks.isEmpty {
                    state.lens = .effort
                }
                recompute(&state)
                return .none

            case let .view(.divisionChanged(division)):
                state.division = division
                state.hasPickedDivision = true
                recompute(&state)
                return .none

            case let .dayEntriesUpdated(entries):
                state.dayEntries = entries
                state.isDayLoaded = true
                if !state.hasPickedDivision, let mine = entries.first(where: { $0.uid == state.myUid }) {
                    state.division = mine.division
                }
                // The shown day's live entries also refresh its column of a loaded week.
                let day = state.day
                if state.weekEntries?[day] != nil {
                    state.weekEntries?[day] = entries
                }
                recompute(&state)
                if state.range == .day {
                    state.viewState = .success
                }
                return .none

            case let .weekLoaded(entriesByDay):
                // Live entries may have arrived first; they are fresher than this one-shot read.
                var merged = entriesByDay
                if merged[state.day] != nil, state.isDayLoaded {
                    merged[state.day] = state.dayEntries
                }
                state.weekEntries = merged
                recompute(&state)
                if state.range == .week {
                    state.viewState = .success
                }
                return .none

            case .failed:
                state.viewState = .failed
                return .none
            }
        }
    }

    // Rows are derived once per input change, never in the view.
    private func recompute(_ state: inout State) {
        let weightsVersion = EffortPointsScoring.currentWeightsVersion
        state.dayRows = TeamLeaderboardRanker.rows(
            entries: state.dayEntries,
            lens: state.lens,
            blockId: state.selectedBlockId,
            division: state.division,
            myUid: state.myUid,
            weightsVersion: weightsVersion
        )
        state.weekRows = TeamWeekStandings.rows(
            entriesByDay: state.weekEntries ?? [:],
            myUid: state.myUid,
            weightsVersion: weightsVersion
        )
    }

    private func listenToDay(groupId: String, day: String) -> Effect<Action> {
        .run { [teamClient] send in
            for try await entries in teamClient.observeDayEntries(groupId, day) {
                await send(.dayEntriesUpdated(entries))
            }
        } catch: { error, send in
            Logger.team.error("Day entries failed: \(error.localizedDescription)")
            await send(.failed)
        }
        .cancellable(id: GroupLeaderboardCancelID.dayEntries, cancelInFlight: true)
    }

    private func loadWeek(groupId: String, days: [String]) -> Effect<Action> {
        .run { [teamClient] send in
            await send(.weekLoaded(try await teamClient.weekEntries(groupId, days)))
        } catch: { error, send in
            Logger.team.error("Week entries failed: \(error.localizedDescription)")
            await send(.failed)
        }
        .cancellable(id: GroupLeaderboardCancelID.week, cancelInFlight: true)
    }
}
