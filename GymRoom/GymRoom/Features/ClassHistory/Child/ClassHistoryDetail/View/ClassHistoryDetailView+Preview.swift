//
//  ClassHistoryDetailView+Preview.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

#if DEBUG
import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

/// Helper budujący `State` z syntetycznymi 4 atletami (Seba/Anna/Marek/Kasia)
/// dla CrossFit-style klasy (warmup + WOD1 + WOD2 + cooldown). `phaseScale: 1.0` =
/// 30-min, `2.0` = 60-min — skaluje proporcjonalnie wszystkie 4 fazy.
private func previewState(
    chartViewMode: ClassHistoryDetailFeature.ChartViewMode,
    phaseScale: Double = 1.0,
    includeAthletes: Bool = true
) -> ClassHistoryDetailFeature.State {
    let classStart = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    let baseClassDuration: TimeInterval = 30 * 60
    let athletes: [AthleteSummary] = includeAthletes
        ? AthleteSummary.previewClass(classStart: classStart, phaseScale: phaseScale)
        : []
    let ranges = Dictionary(uniqueKeysWithValues: athletes.map {
        ($0.id, HRSample.minuteRanges(from: $0.samples))
    })
    return ClassHistoryDetailFeature.State(
        sessionId: UUID(),
        className: "CrossFit · Open Class",
        location: "Studio A",
        startedAt: classStart,
        endedAt: classStart.addingTimeInterval(baseClassDuration * phaseScale),
        viewState: .success,
        athletes: athletes,
        hrRangesByAthlete: ranges,
        chartViewMode: chartViewMode
    )
}

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
                    viewState: .failed
                )
            ) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#Preview("Per athlete · 30-min class") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .perAthlete)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#Preview("Per athlete · 60-min class") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .perAthlete, phaseScale: 2.0)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#Preview("Combined · multi-series line") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .combined)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#Preview("Empty class") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .perAthlete, includeAthletes: false)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

/// Klasa krótsza niż próg `minDurationForAnalytics` (5 min) — wyzwala
/// `ContentUnavailableView` placeholdery na wszystkich chartach. `phaseScale: 0.04`
/// = 30 min × 0.04 = ~72 sek (analog real-world Strength 1m 18s case).
#Preview("Insufficient data · combined") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .combined, phaseScale: 0.04)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#Preview("Insufficient data · per athlete") {
    NavigationStack {
        ClassHistoryDetailView(
            store: Store(initialState: previewState(chartViewMode: .perAthlete, phaseScale: 0.04)) {
                ClassHistoryDetailFeature()
            }
        )
    }
}

#endif
