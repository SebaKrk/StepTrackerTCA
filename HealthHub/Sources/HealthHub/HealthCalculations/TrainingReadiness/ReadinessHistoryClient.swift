//
//  ReadinessHistoryClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels

/// Stores and reads daily readiness scores.
///
/// Readiness is calculated from HealthKit on demand, which answers "how am I
/// today" but never "how was I last Tuesday" — nobody remembers their score
/// from three days ago. This client is what makes the day survive the day.
public struct ReadinessHistoryClient: Sendable {

    /// Saves a day's result, replacing any earlier row for the same day.
    public var save: @Sendable (TrainingReadinessResult, ReadinessDay) async throws -> Void

    /// Saves many days in one transaction, replacing earlier rows for those days.
    public var saveMany: @Sendable ([ReadinessDayResult]) async throws -> Void

    /// Reads the most recent days, oldest first.
    public var history: @Sendable (_ days: Int) async throws -> [TrainingReadinessResult]

    /// Algorithm version the stored history was last rebuilt for, or zero.
    ///
    /// A rebuild is what makes old rows comparable with new ones, so this is the
    /// same invariant as `ReadinessAlgorithm.currentVersion` seen from storage.
    public var backfilledVersion: @Sendable () -> Int

    /// Records that history has been rebuilt for a version.
    public var setBackfilledVersion: @Sendable (Int) -> Void

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - save: Stores one day's result
    ///   - history: Reads recent days
    public init(
        save: @escaping @Sendable (TrainingReadinessResult, ReadinessDay) async throws -> Void,
        saveMany: @escaping @Sendable ([ReadinessDayResult]) async throws -> Void,
        history: @escaping @Sendable (_ days: Int) async throws -> [TrainingReadinessResult],
        backfilledVersion: @escaping @Sendable () -> Int,
        setBackfilledVersion: @escaping @Sendable (Int) -> Void
    ) {
        self.save = save
        self.saveMany = saveMany
        self.history = history
        self.backfilledVersion = backfilledVersion
        self.setBackfilledVersion = setBackfilledVersion
    }
}

// MARK: - DependencyKey

extension ReadinessHistoryClient: DependencyKey {

    public static let liveValue: ReadinessHistoryClient = {
        @Dependency(\.defaultDatabase) var database

        return ReadinessHistoryClient(
            save: { result, day in
                try await database.write { db in
                    let record = TrainingReadinessRecord(
                        result: result,
                        day: day,
                        algorithmVersion: ReadinessAlgorithm.currentVersion
                    )
                    try TrainingReadinessRecord.upsert { record }.execute(db)
                }
            },
            saveMany: { entries in
                // One transaction for the whole batch: a backfill writes dozens of
                // days and a transaction each would fsync dozens of times.
                try await database.write { db in
                    for entry in entries {
                        let record = TrainingReadinessRecord(
                            result: entry.result,
                            day: entry.day,
                            algorithmVersion: ReadinessAlgorithm.currentVersion
                        )
                        try TrainingReadinessRecord.upsert { record }.execute(db)
                    }
                }
            },
            history: { days in
                @Dependency(\.date.now) var now
                @Dependency(\.calendar) var calendar

                guard let cutoffDay = calendar.date(
                    byAdding: .day,
                    value: -max(days, 1),
                    to: calendar.startOfDay(for: now)
                ) else { return [] }

                // Keys are `yyyy-MM-dd`, so a text comparison orders them by date.
                let cutoff = ReadinessDayKey.key(for: cutoffDay, calendar: calendar)

                return try await database.read { db in
                    try TrainingReadinessRecord
                        .where { $0.id.gte(cutoff) }
                        .order { $0.id.asc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            },
            backfilledVersion: {
                UserDefaults.standard.integer(forKey: backfilledVersionKey)
            },
            setBackfilledVersion: { version in
                UserDefaults.standard.set(version, forKey: backfilledVersionKey)
            }
        )
    }()

    /// Where the rebuilt-for version is remembered.
    private static let backfilledVersionKey = "readinessHistoryBackfilledVersion"

    public static var testValue: ReadinessHistoryClient {
        ReadinessHistoryClient(
            save: unimplemented("ReadinessHistoryClient.save"),
            saveMany: unimplemented("ReadinessHistoryClient.saveMany"),
            history: unimplemented("ReadinessHistoryClient.history", placeholder: []),
            backfilledVersion: unimplemented("ReadinessHistoryClient.backfilledVersion", placeholder: 0),
            setBackfilledVersion: unimplemented("ReadinessHistoryClient.setBackfilledVersion")
        )
    }
}

// MARK: - DependencyValues

public extension DependencyValues {
    var readinessHistoryClient: ReadinessHistoryClient {
        get { self[ReadinessHistoryClient.self] }
        set { self[ReadinessHistoryClient.self] = newValue }
    }
}
