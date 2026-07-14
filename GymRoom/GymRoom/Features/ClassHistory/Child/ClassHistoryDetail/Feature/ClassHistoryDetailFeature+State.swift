//
//  ClassHistoryDetailFeature+State.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ClassHistoryDetailFeature {

    @ObservableState
    struct State: Equatable {

        /// Snapshot session metadata (z `ClassSessionRecord` przy push z History row).
        let sessionId: UUID
        let className: String
        let location: String
        let startedAt: Date
        let endedAt: Date?

        /// Loading state widoku — `.loading` na start (gdy decode BLOB-ów trwa
        /// 1-3 sek), `.success` po `athletesLoaded`, `.failed` na `fetchFailed`.
        /// Bez tego user widzi pusty topStatsBanner (0/0/—) zanim decode dojdzie.
        var viewState: ViewState = .loading

        /// Decoded athletes z BLOB-ów — async fetch + decode w `viewDidAppear`.
        var athletes: [AthleteSummary] = []

        /// Pre-aggregated range bars per athlete. Liczone raz w `athletesLoaded`
        /// (off main thread, w `.run`), trzymane do końca życia feature'a.
        /// Klucz = `athlete.id`. Empty = nie liczone albo athlete bez samples.
        var hrRangesByAthlete: [UUID: [HRMinuteRange]] = [:]

        /// Gap-aware line segments for the combined chart, keyed by `athlete.id`.
        /// Precomputed once in `athletesLoaded` (scrubbing re-evaluates the chart
        /// body per frame — the O(n) split must not run there). A measurement gap
        /// (> `AthleteSummary.maxContinuousSampleGap`) starts a new segment, so the
        /// chart shows a hole instead of bridging the outage with a straight line.
        var hrSegmentsByAthlete: [UUID: [AthleteSummary.HRSegment]] = [:]

        /// Measurement outages per athlete, derived from `hrSegmentsByAthlete` in
        /// the `athletesLoaded` handler. Per-athlete cards shade these intervals
        /// (RectangleMark band) and show a "no measurement" legend note.
        var hrGapsByAthlete: [UUID: [AthleteSummary.HRGap]] = [:]

        /// Wybrana minuta per athlete (klucz = `athlete.id`). Brak entry w dict =
        /// brak selection dla danego athlete'a. Każda karta ma własną selection
        /// (combined mode nie używa).
        var selectedMinutes: [UUID: Date] = [:]

        /// Cumulative angular position w pie chart kalorii (`.combined` mode).
        /// Charts wysyła kąt jako cumulative `Double` w skali sumy kcal — View
        /// helper mapuje na konkretnego athletę. `nil` = brak selection
        /// (center label pokazuje TOTAL klasy).
        var selectedKcalAngle: Double? = nil

        /// Cumulative angular position w donucie stref HR (`.combined` mode) — analog
        /// `selectedKcalAngle`. Charts wysyła kąt w skali sumy sekund wszystkich stref;
        /// View helper mapuje na konkretną strefę. `nil` = brak selection (center label
        /// pokazuje TOTAL czasu klasy w strefach).
        var selectedZoneAngle: Double? = nil

        /// Wybrany timestamp w combined HR chart (multi-series LineMark). Charts wysyła
        /// dokładny Date; View helper mapuje na najbliższy sample każdego atlety i
        /// pokazuje annotation z listą `nick + BPM` (sorted descending). `nil` = brak
        /// selection (chart bez RuleMark/PointMark/annotation).
        var selectedCombinedTime: Date? = nil

        /// Toggle widoku HR chart — `combined` (multi-series LineMark + donut pie kalorii)
        /// vs `perAthlete` (lista kart per peer z BarMark range + selection)
        /// vs `points` (ranking table — IPAD-00095-B).
        var chartViewMode: ChartViewMode = .combined

        /// Ranking table (IPAD-00095-B) — the same `ClassResultsFeature` shown
        /// after class end, here embedded as the "Points" tab. Rows populated in
        /// `athletesLoaded` from the already-decoded analytics.
        var results: ClassResultsFeature.State = .init()

        /// Zone-color background on the combined chart (Myzone-style). When ON the
        /// Y axis switches from BPM to %HRmax — zone boundaries are per-athlete in
        /// absolute BPM (different maxHR each), so universal horizontal bands are
        /// only honest on a relative scale. OFF = plain BPM chart, unchanged.
        var showsZoneBands: Bool = false

        /// Confirm alert przed cascade delete sesji z ellipsis menu → "Usuń".
        @Presents var alert: AlertState<Action.Alert>?
    }

    /// Tryby wyświetlania zawartości detail'u. Switch'owane przez `SegmentedPicker`
    /// w View — trzy taby: Team / Individual / Points (user decyzja 2026-07-09).
    enum ChartViewMode: String, CaseIterable, Identifiable, Sendable, Equatable {

        /// Multi-series LineMark — wszyscy athletes na jednej skali czasu, kolor per nick.
        /// Bez selection (niepotrzebne dla overlay comparison).
        case combined

        /// Lista kart per athlete, każda z **BarMark range** per-minute + selection.
        /// Range bar pokazuje min/max BPM w danej minucie.
        case perAthlete

        /// Ranking table po punktach (IPAD-00095-B) — reuse `ClassResultsTableView`.
        case points

        var id: String { rawValue }

        var title: String {
            switch self {
            case .combined: String(localized: "Team", bundle: .main)
            case .perAthlete: String(localized: "Individual", bundle: .main)
            case .points: String(localized: "Points", bundle: .main)
            }
        }
    }
}
