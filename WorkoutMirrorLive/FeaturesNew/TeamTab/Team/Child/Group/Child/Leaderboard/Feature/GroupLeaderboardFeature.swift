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

/// Leaderboard section of the group screen: today's ranking and the week table.
@Reducer
struct GroupLeaderboardFeature {

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.viewDidAppear):
                let now = date.now
                state.today = TeamDay.id(for: now, calendar: calendar)
                state.weekDays = TeamDay.weekIds(containing: now, calendar: calendar)
                state.weekEntries = nil
                return .merge(
                    listenToDay(groupId: state.groupId, day: state.today),
                    state.range == .week ? loadWeek(groupId: state.groupId, days: state.weekDays) : .none
                )

            case let .view(.rangeChanged(range)):
                state.range = range
                guard range == .week, state.weekEntries == nil else {
                    state.viewState = .success
                    return .none
                }
                state.viewState = .loading
                return loadWeek(groupId: state.groupId, days: state.weekDays)

            case let .view(.lensChanged(lens)):
                state.lens = lens
                recompute(&state)
                return .none

            case let .view(.divisionChanged(division)):
                state.division = division
                recompute(&state)
                return .none

            case let .dayEntriesUpdated(entries):
                state.dayEntries = entries
                // Today's live entries also refresh today's column of a loaded week.
                let today = state.today
                if state.weekEntries?[today] != nil {
                    state.weekEntries?[today] = entries
                }
                recompute(&state)
                if state.range == .day {
                    state.viewState = .success
                }
                return .none

            case let .weekLoaded(entriesByDay):
                state.weekEntries = entriesByDay
                recompute(&state)
                state.viewState = .success
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
            division: state.division,
            myUid: state.myUid,
            weightsVersion: weightsVersion
        )
        state.weekRows = TeamWeekStandings.rows(
            entriesByDay: state.weekEntries ?? [:],
            days: state.weekDays,
            lens: state.lens,
            division: state.division,
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
    }
}
