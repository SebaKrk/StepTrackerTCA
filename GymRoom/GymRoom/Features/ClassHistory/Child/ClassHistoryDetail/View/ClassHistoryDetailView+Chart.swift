//
//  ClassHistoryDetailView+Chart.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import Charts
import SharedModels
import SwiftUI

extension ClassHistoryDetailView {

    /// Range bar dla pojedynczej minuty — odcinek pionowy od `minHR` do `maxHR`.
    /// Wyszary'owany gdy w danym chart'cie jest selection i to NIE jest wybrany słupek.
    func createBarMark(_ range: HRMinuteRange, isSelected: Bool, style: some ShapeStyle) -> some ChartContent {
        BarMark(
            x: .value("Minute", range.minute, unit: .minute),
            yStart: .value("HR min", range.minHR),
            yEnd: .value("HR max", range.maxHR),
            width: .ratio(0.8)
        )
        .foregroundStyle(style)
        .opacity(isSelected ? 1.0 : 0.5)
        .cornerRadius(3)
    }

    /// Gap-aware HR lines for one athlete on the combined chart. One `LineMark`
    /// series PER SEGMENT — Charts connects every point within a series, so a
    /// measurement gap would otherwise get bridged with a straight line. Color and
    /// legend stay per athlete via `foregroundStyle(by:)` (single legend entry).
    ///
    /// `relativeTo`: non-nil switches the Y value from absolute BPM to % of the
    /// athlete's own max — required by the zone-band background (zone boundaries
    /// in BPM differ per athlete, so shared bands only work on a relative scale).
    ///
    /// Extracted from the `Chart { }` closure — the triple-nested ForEach exceeded
    /// the type-checker's budget ("unable to type-check in reasonable time").
    @ChartContentBuilder
    func athleteHRLines(
        _ athlete: AthleteSummary,
        segments: [AthleteSummary.HRSegment],
        relativeTo maxHR: Int? = nil
    ) -> some ChartContent {
        ForEach(segments) { segment in
            ForEach(segment.samples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", hrChartValue(bpm: sample.bpm, relativeTo: maxHR)),
                    series: .value("Series", "\(athlete.nick)#\(segment.id)")
                )
                .foregroundStyle(by: .value("Athlete", athlete.nick))
                .interpolationMethod(.monotone)
            }
        }
    }

    /// Y value for an HR sample — absolute BPM, or % of the athlete's own max
    /// when the zone-band background is on. Guards against a zero max snapshot.
    func hrChartValue(bpm: Int, relativeTo maxHR: Int?) -> Double {
        guard let maxHR, maxHR > 0 else { return Double(bpm) }
        return Double(bpm) / Double(maxHR) * 100
    }

    /// Myzone-style horizontal zone bands behind the combined chart (%HRmax scale).
    /// Training zones only — `resting` spans down to 0% and would crush the plot;
    /// below Zone 1 there is simply "no zone" (same call Myzone and Apple make).
    /// Same opacity treatment as the measurement-gap bands, rotated 90°.
    @ChartContentBuilder
    func zoneBands() -> some ChartContent {
        ForEach(HeartRateZone.allCases.filter { $0 != .resting }) { zone in
            RectangleMark(
                yStart: .value("Zone start", zone.percentageRange.lowerBound * 100),
                yEnd: .value("Zone end", zone.percentageRange.upperBound * 100)
            )
            .foregroundStyle(zone.color.opacity(0.14))
        }
    }

    /// Shaded vertical bands over measurement outages (athlete out of BLE range) —
    /// the empty stretch on a card must read as "no measurement", not "no effort".
    /// Paired with a legend note under the chart (`gapLegendNote`).
    @ChartContentBuilder
    func measurementGapBands(_ gaps: [AthleteSummary.HRGap]) -> some ChartContent {
        ForEach(gaps) { gap in
            // Minute-aligned edges — raw sample timestamps would cut through the
            // neighboring minute buckets and overlap the boundary bars.
            if let band = gap.minuteAlignedBand {
                RectangleMark(
                    xStart: .value("Gap start", band.lowerBound),
                    xEnd: .value("Gap end", band.upperBound)
                )
                .foregroundStyle(.red.opacity(0.14))
            }
        }
    }

    /// Pionowa linia + annotation na wybranej minucie. Analog
    /// `HeartRateDetailsView+Chart.createRuleMark`. Annotation pozycjonowany
    /// bottomTrailing z `overflowResolution(.fit(to: .chart))` — nigdy nie wyleci
    /// poza obszar wykresu.
    func createRuleMark<Content: View>(
        with selectedDate: Date,
        @ViewBuilder annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Minute", selectedDate, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -30)
            .annotation(
                position: .bottomTrailing,
                spacing: 4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                annotationView()
            }
    }

}
