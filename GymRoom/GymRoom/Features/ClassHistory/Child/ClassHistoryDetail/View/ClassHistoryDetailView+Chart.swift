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
    /// Extracted from the `Chart { }` closure — the triple-nested ForEach exceeded
    /// the type-checker's budget ("unable to type-check in reasonable time").
    @ChartContentBuilder
    func athleteHRLines(
        _ athlete: AthleteSummary,
        segments: [AthleteSummary.HRSegment]
    ) -> some ChartContent {
        ForEach(segments) { segment in
            ForEach(segment.samples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm),
                    series: .value("Series", "\(athlete.nick)#\(segment.id)")
                )
                .foregroundStyle(by: .value("Athlete", athlete.nick))
                .interpolationMethod(.monotone)
            }
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
