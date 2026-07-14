//
//  ExerciseAnalyticsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct ExerciseAnalyticsFeature {

    // MARK: - Dependency

    @Dependency(\.exerciseLogClient) var exerciseLogClient
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.onAppear):
                guard state.exerciseLogs.isEmpty else { return .none }
                state.selectedMonth = now
                return loadLogs(for: state.selectedMonth)

            case let .view(.monthChanged(date)):
                state.selectedMonth = date
                state.isChartAnimated = false
                return loadLogs(for: date)

            case let .view(.sortModeChanged(mode)):
                state.sortMode = mode
                return .none

            case let .view(.exerciseTapped(exerciseType)):
                state.detail = ExerciseDetailFeature.State(exerciseType: exerciseType)
                return .none

            case let .logsLoaded(logs):
                state.exerciseLogs = logs
                state.weeklyBreakdown = computeWeeklyBreakdown(from: logs)
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.revealChart)
                }

            case .revealChart:
                state.isChartAnimated = true
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            ExerciseDetailFeature()
        }
    }

    // MARK: - Private

    private func loadLogs(for date: Date) -> Effect<Action> {
        .run { [exerciseLogClient, calendar] send in
            let components = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: components) ?? date
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
            let logs = try await exerciseLogClient.fetchByDateRange(start, end)
            await send(.logsLoaded(logs))
        }
    }

    private func computeWeeklyBreakdown(from logs: [ExerciseLog]) -> [[MovementCategory: Int]] {
        let grouped = Dictionary(grouping: logs) { log in
            calendar.component(.weekOfMonth, from: log.date)
        }
        let maxWeek = grouped.keys.max() ?? 4
        return (1...maxWeek).map { week in
            let weekLogs = grouped[week] ?? []
            return Dictionary(grouping: weekLogs) { $0.category ?? .mixed }
                .mapValues(\.count)
        }
    }
}
