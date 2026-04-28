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
                state.selectedMonth = now
                return loadLogs(for: state.selectedMonth)

            case let .view(.monthChanged(date)):
                state.selectedMonth = date
                return loadLogs(for: date)

            case let .view(.sortModeChanged(mode)):
                state.sortMode = mode
                return .none

            case .view(.exerciseTapped):
                // Navigation handled by parent
                return .none

            case let .logsLoaded(logs):
                state.exerciseLogs = logs
                return .none
            }
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
}
