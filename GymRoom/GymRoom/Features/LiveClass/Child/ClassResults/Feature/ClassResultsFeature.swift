//
//  ClassResultsFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 09/07/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// End-of-class results screen (IPAD-00095-A): a native `Table` ranking every
/// athlete of the finished session by effort points.
///
/// Presented by `LiveClassFeature` as a fullScreenCover AFTER `endSession`
/// finalized the per-athlete analytics in the database and BEFORE
/// `delegate(.classEnded)` — the parent's `classEnded` handler tears the whole
/// cover stack down, so it must fire only from "Done" here.
@Reducer
struct ClassResultsFeature {

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .delegate:
                return .none

            case .view(.doneTapped):
                return .send(.delegate(.done))
            }
        }
    }
}

// MARK: - Row building

extension ClassResultsFeature {

    /// Maps persisted athlete records to table rows, decoding the FROZEN
    /// `ClassAnalytics` blob written by `endSession`. Records with an
    /// undecodable blob are skipped (same policy as ClassHistoryDetail).
    ///
    /// `nonisolated` — called from the `confirmEnd` `.run` effect under the
    /// project's `defaultIsolation(MainActor.self)`.
    nonisolated static func rows(from records: [AthleteSessionRecord]) -> [ResultRow] {
        let decoder = JSONDecoder()
        return records.compactMap { record in
            guard let analytics = try? decoder.decode(ClassAnalytics.self, from: record.aggregatedStatsData) else {
                Logger.gymRoom.error("❌ ClassResults: failed to decode analytics for athlete \(record.id)")
                return nil
            }
            return makeRow(id: record.id, nick: record.nick, analytics: analytics)
        }
    }

    /// Maps already-decoded athletes (ClassHistoryDetail's model) to table rows —
    /// the "Points" tab in the history detail reuses the exact same ranking.
    nonisolated static func rows(from summaries: [AthleteSummary]) -> [ResultRow] {
        summaries.map { athlete in
            makeRow(id: athlete.id, nick: athlete.nick, analytics: athlete.analytics)
        }
    }

    /// Single source of the analytics → row mapping for both builders.
    private nonisolated static func makeRow(id: UUID, nick: String, analytics: ClassAnalytics) -> ResultRow {
        ResultRow(
            id: id,
            nick: nick,
            points: analytics.effortPoints ?? 0,
            hasPoints: analytics.effortPoints != nil,
            avgHR: analytics.avgHR,
            peakHR: analytics.peakHR,
            calories: Int(analytics.totalCalories.rounded()),
            durationMinutes: Int(analytics.durationSeconds / 60)
        )
    }
}
