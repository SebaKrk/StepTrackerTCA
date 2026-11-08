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

    /// Reads the most recent days, oldest first.
    public var history: @Sendable (_ days: Int) async throws -> [TrainingReadinessResult]

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - save: Stores one day's result
    ///   - history: Reads recent days
    public init(
        save: @escaping @Sendable (TrainingReadinessResult, ReadinessDay) async throws -> Void,
        history: @escaping @Sendable (_ days: Int) async throws -> [TrainingReadinessResult]
    ) {
        self.save = save
        self.history = history
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
            history: { days in
                @Dependency(\.date.now) var now
                @Dependency(\.calendar) var calendar

                guard let cutoff = calendar.date(
                    byAdding: .day,
                    value: -max(days, 1),
                    to: calendar.startOfDay(for: now)
                ) else { return [] }

                return try await database.read { db in
                    try TrainingReadinessRecord
                        .where { $0.id.gte(cutoff) }
                        .order { $0.id.asc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            }
        )
    }()

    public static var testValue: ReadinessHistoryClient {
        ReadinessHistoryClient(
            save: unimplemented("ReadinessHistoryClient.save"),
            history: unimplemented("ReadinessHistoryClient.history", placeholder: [])
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
