//
//  PRBoardFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

extension PRBoardFeature {

    @ObservableState
    struct State {

        // MARK: - Presentation

        /// Movement list of the tapped category.
        @Presents var movementList: PRMovementListFeature.State?

        // MARK: - Observed entries

        /// Observed PR entries (SQLiteData) — the database pushes updates on every
        /// save/delete, so counters refresh without manual refetch.
        /// `@ObservationStateIgnored` — FetchAll has its own observation (SharedReader).
        @ObservationStateIgnored
        @FetchAll(PREntryRecord.all)
        var entryRecords

        // MARK: - Derived

        /// Decoded domain entries (rows with unreadable score are skipped defensively).
        var entries: [PREntry] {
            entryRecords.compactMap { $0.toDomain() }
        }

        /// Distinct movements with at least one entry — the hero "N/M" counter.
        var completedCount: Int {
            PRResolver.completedMovementIds(entries: entries).count
        }

        /// Most recent entry overall — the hero "latest PR" row.
        var latestEntry: PREntry? {
            entries.max { lhs, rhs in
                (lhs.date, lhs.createdAt) < (rhs.date, rhs.createdAt)
            }
        }

        /// Distinct movements with at least one entry, per category — the "N/M" counters.
        var completedCountByCategory: [PRCategory: Int] {
            let completedIds = PRResolver.completedMovementIds(entries: entries)
            var counts: [PRCategory: Int] = [:]
            for id in completedIds {
                guard let category = PRCatalog.movement(id: id)?.category else { continue }
                counts[category, default: 0] += 1
            }
            return counts
        }

        /// Day of the most recent entry per category — the "last PR" label.
        var latestDateByCategory: [PRCategory: Date] {
            var latest: [PRCategory: Date] = [:]
            for entry in entries {
                guard let category = PRCatalog.movement(id: entry.movementId)?.category else { continue }
                if let current = latest[category] {
                    if entry.date > current { latest[category] = entry.date }
                } else {
                    latest[category] = entry.date
                }
            }
            return latest
        }
    }
}
