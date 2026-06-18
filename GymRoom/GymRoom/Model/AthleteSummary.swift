//
//  AthleteSummary.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import Foundation
import SharedModels

/// Domain wrapper dla decoded `AthleteSessionRecord` — używany w ClassHistoryDetail.
///
/// Reducer fetch'uje `AthleteSessionRecord` z bazy, decoduje BLOB-y
/// (`hrSamplesData` → `[HRSample]`, `aggregatedStatsData` → `ClassAnalytics`)
/// raz w `viewDidAppear`, propaguje do State jako `[AthleteSummary]`. View
/// konsumuje **decoded** structures bez JSONDecoder calls w body (performance).
struct AthleteSummary: Identifiable, Sendable, Equatable {
    let id: UUID                  // = AthleteSessionRecord.id
    let deviceID: UUID            // stable per-install peer ID (do color mapping)
    let nick: String              // display name
    let maxHR: Int                // snapshot z momentu pierwszego sample
    let joinedAt: Date
    let leftAt: Date?
    let samples: [HRSample]       // decoded chronological
    let analytics: ClassAnalytics // decoded aggregates
}
