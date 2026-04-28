//
//  ExerciseDetailFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ExerciseDetailFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        let exerciseType: ExerciseType
        var logs: [ExerciseLog] = []

        // MARK: - Computed — Header

        var displayName: String { exerciseType.displayName }
        var category: MovementCategory { exerciseType.category }
        var count: Int { logs.count }

        var pr: Double? {
            logs.compactMap(\.actualWeight).max()
        }

        var avgHR: Double? {
            let hrs = logs.compactMap(\.avgHeartRate)
            guard !hrs.isEmpty else { return nil }
            return hrs.reduce(0, +) / Double(hrs.count)
        }

        var maxHR: Double? {
            logs.compactMap(\.maxHeartRate).max()
        }

        // MARK: - Computed — Weight Progression Chart

        var weightProgression: [(date: Date, weight: Double)] {
            logs.compactMap { log in
                guard let w = log.actualWeight else { return nil }
                return (date: log.date, weight: w)
            }
            .sorted { $0.date < $1.date }
        }

        // MARK: - Computed — Weekly Volume Chart

        var weeklyVolume: [(week: Date, volume: Double)] {
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: logs) { log in
                calendar.startOfWeek(for: log.date)
            }
            return grouped.map { weekStart, weekLogs in
                (week: weekStart, volume: weekLogs.compactMap(\.volumeLoad).reduce(0, +))
            }
            .sorted { $0.week < $1.week }
        }

        // MARK: - Computed — HR per Session Chart

        var hrPerSession: [(date: Date, avgHR: Double)] {
            logs.compactMap { log in
                guard let hr = log.avgHeartRate else { return nil }
                return (date: log.date, avgHR: hr)
            }
            .sorted { $0.date < $1.date }
        }
    }
}

// MARK: - Calendar Helper

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
