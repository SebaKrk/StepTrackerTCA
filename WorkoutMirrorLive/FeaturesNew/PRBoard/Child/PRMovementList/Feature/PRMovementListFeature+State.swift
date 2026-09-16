//
//  PRMovementListFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

extension PRMovementListFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Category whose movements this list presents.
        let category: PRCategory

        /// Movement detail pushed from a tapped row.
        @Presents var detail: PRMovementDetailFeature.State?

        // MARK: - Observed entries

        /// Observed PR entries (SQLiteData) — rows un-mute and show values without
        /// manual refetch. `@ObservationStateIgnored` — FetchAll observes itself.
        @ObservationStateIgnored
        @FetchAll(PREntryRecord.all)
        var entryRecords

        // MARK: - Derived

        /// Subgroups of this category in catalog declaration order.
        var sections: [(subgroup: PRSubgroup, movements: [PRMovement])] {
            var order: [PRSubgroup] = []
            var grouped: [PRSubgroup: [PRMovement]] = [:]
            for movement in PRCatalog.movements(in: category) {
                if grouped[movement.subgroup] == nil { order.append(movement.subgroup) }
                grouped[movement.subgroup, default: []].append(movement)
            }
            return order.map { (subgroup: $0, movements: grouped[$0] ?? []) }
        }

        /// Decoded entries grouped by movement (whole table — small by design).
        var entriesByMovement: [String: [PREntry]] {
            Dictionary(grouping: entryRecords.compactMap { $0.toDomain() }, by: \.movementId)
        }

        /// Formatted current PR per movement id; missing key = no entries (muted row).
        /// Dictionary property (not a method) — the store's dynamic member lookup
        /// only exposes State properties.
        var prLabelByMovementId: [String: String] {
            var labels: [String: String] = [:]
            for (movementId, entries) in entriesByMovement {
                guard let movement = PRCatalog.movement(id: movementId) else { continue }
                let summary = PRResolver.summary(for: movement, entries: entries)
                if let best = summary.best {
                    labels[movementId] = PRScoreFormatter.string(for: best.score)
                }
            }
            return labels
        }

        /// Completed movements per subgroup — the "N/M" header counters.
        var completedCountBySubgroup: [PRSubgroup: Int] {
            let completed = Set(prLabelByMovementId.keys)
            var counts: [PRSubgroup: Int] = [:]
            for section in sections {
                counts[section.subgroup] =
                    section.movements.filter { completed.contains($0.id) }.count
            }
            return counts
        }

        /// Day of the most recent entry per movement — the row sublabel.
        var latestDateByMovementId: [String: Date] {
            entriesByMovement.compactMapValues { entries in
                entries.map(\.date).max()
            }
        }

        // MARK: - Init

        init(category: PRCategory) {
            self.category = category
        }
    }
}
