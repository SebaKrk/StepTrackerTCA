//
//  ClassHistoryDetailView+Preview.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

#if DEBUG
import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

private let baseClassDuration: TimeInterval = 30 * 60

/// Błąd wstrzykiwany do `fetchAthletesForSession` w preview "Failed state" —
/// reducer złapie go w `catch` i wyśle `.fetchFailed` → `viewState = .failed`.
private struct PreviewFetchError: Error {}

// MARK: - Preview store factory

/// Buduje `Store` dla preview z **nadpisanym** `gymClassClient`. Bez tego override
/// `.task { viewDidAppear }` w View dotyka live SQLiteData (`defaultDatabase`),
/// którego preview nie konfiguruje → crash agenta preview ("failed to load").
///
/// Dane płyną prawdziwą ścieżką reducera: override zwraca syntetyczne
/// `AthleteSessionRecord` (z zakodowanymi BLOB-ami), reducer dekoduje je z powrotem
/// na `AthleteSummary`, liczy `hrRangesByAthlete` i ustawia `.success`.
private func previewStore(
    chartViewMode: ClassHistoryDetailFeature.ChartViewMode,
    phaseScale: Double = 1.0,
    includeAthletes: Bool = true
) -> StoreOf<ClassHistoryDetailFeature> {
    let classStart = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    let athletes: [AthleteSummary] = includeAthletes
        ? AthleteSummary.previewClass(classStart: classStart, phaseScale: phaseScale)
        : []

    return Store(
        initialState: ClassHistoryDetailFeature.State(
            sessionId: UUID(),
            className: "CrossFit · Open Class",
            location: "Studio A",
            startedAt: classStart,
            endedAt: classStart.addingTimeInterval(baseClassDuration * phaseScale),
            viewState: .loading,
            chartViewMode: chartViewMode
        )
    ) {
        ClassHistoryDetailFeature()
    } withDependencies: {
        $0.gymClassClient.fetchAthletesForSession = { _ in
            athletes.map(AthleteSessionRecord.preview(from:))
        }
    }
}

// MARK: - AthleteSessionRecord preview factory

private extension AthleteSessionRecord {

    /// Koduje syntetyczny `AthleteSummary` z powrotem do persisted record (BLOB-y JSON),
    /// tak jak production zapis. Dzięki temu preview przechodzi przez ten sam decode
    /// w reducerze co prawdziwy fetch z bazy — zero rozjazdu z runtime'em.
    static func preview(from summary: AthleteSummary) -> AthleteSessionRecord {
        let encoder = JSONEncoder()
        return AthleteSessionRecord(
            id: summary.id,
            classSessionId: UUID(),
            deviceID: summary.deviceID,
            nick: summary.nick,
            maxHR: summary.maxHR,
            hrSamplesData: (try? encoder.encode(summary.samples)) ?? Data(),
            aggregatedStatsData: (try? encoder.encode(summary.analytics)) ?? Data(),
            joinedAt: summary.joinedAt,
            leftAt: summary.leftAt,
            createdAt: summary.joinedAt,
            updatedAt: summary.leftAt ?? summary.joinedAt
        )
    }
}

// MARK: - Previews

#Preview("Loading state") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(
                initialState: ClassHistoryDetailFeature.State(
                    sessionId: UUID(),
                    className: "CrossFit · Open Class",
                    location: "Studio A",
                    startedAt: Date(),
                    endedAt: nil,
                    viewState: .loading
                )
            ) {
                ClassHistoryDetailFeature()
            } withDependencies: {
                // Zawiesza fetch na zawsze → widok zostaje w `.loading`.
                $0.gymClassClient.fetchAthletesForSession = { _ in
                    try await Task.sleep(for: .seconds(3600))
                    return []
                }
            }
        )
    }
}

#Preview("Failed state") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(
                initialState: ClassHistoryDetailFeature.State(
                    sessionId: UUID(),
                    className: "CrossFit · Open Class",
                    location: "Studio A",
                    startedAt: Date(),
                    endedAt: nil,
                    viewState: .loading
                )
            ) {
                ClassHistoryDetailFeature()
            } withDependencies: {
                // Rzuca błąd → reducer `catch` → `.fetchFailed` → `.failed`.
                $0.gymClassClient.fetchAthletesForSession = { _ in
                    throw PreviewFetchError()
                }
            }
        )
    }
}

#Preview("Per athlete · 30-min class") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .perAthlete))
    }
}

#Preview("Per athlete · 60-min class") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .perAthlete, phaseScale: 2.0))
    }
}

#Preview("Combined · multi-series line") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .combined))
    }
}

/// Marek's samples have a cut-out for minutes 12-18 (see `previewClass` dropout) —
/// his card shows the shaded "no measurement" band + the legend note under the
/// chart; the combined line breaks into two segments over the same window.
#Preview("Per athlete · measurement gap (Marek)") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .perAthlete))
    }
}

#Preview("Empty class") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .perAthlete, includeAthletes: false))
    }
}

/// Klasa krótsza niż próg `minDurationForAnalytics` (5 min) — wyzwala
/// `ContentUnavailableView` placeholdery na wszystkich chartach. `phaseScale: 0.04`
/// = 30 min × 0.04 = ~72 sek (analog real-world Strength 1m 18s case).
#Preview("Insufficient data · combined") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .combined, phaseScale: 0.04))
    }
}

#Preview("Insufficient data · per athlete") {
    NavigationStack {
        ClassHistoryDetailView(store: previewStore(chartViewMode: .perAthlete, phaseScale: 0.04))
    }
}

#endif
