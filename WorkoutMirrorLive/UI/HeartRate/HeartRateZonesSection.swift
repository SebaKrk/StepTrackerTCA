//
//  HeartRateZonesSection.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import Charts
import SharedModels
import SwiftUI

// MARK: - Zones card (mockup R4 — Summary)

/// Mockup R4 — HR zones distribution for the Summary screen: header with the
/// dominant-zone dwell time, a proportion band and a per-zone legend with
/// time + percent. Store-agnostic; resting is excluded by design (the card
/// speaks about TRAINING zones). ActivityDetails keeps its own row-based look
/// and shares only the minute chart below.
struct HeartRateZonesSection: View {

    // MARK: - Properties

    let zoneDistribution: [HeartRateZone: TimeInterval]
    let dominantZone: HeartRateZone?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            zoneBand
            zoneLegend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Structure

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            zonesTitle
            Spacer()
            dominantLabel
        }
    }

    /// Proportion band — one rounded segment per zone, width ∝ dwell time.
    private var zoneBand: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(trainingZones) { zone in
                    if duration(of: zone) > 0 {
                        bandSegment(zone: zone, width: segmentWidth(of: zone, in: geometry.size.width))
                    }
                }
            }
        }
        .frame(height: 14)
    }

    private var zoneLegend: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(trainingZones) { zone in
                legendRow(zone: zone)
            }
        }
    }

    // MARK: - Implementation

    private var zonesTitle: some View {
        Text(String(localized: "Heart rate zones", bundle: .main))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(SummaryTheme.ink)
    }

    private func bandSegment(zone: HeartRateZone, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(zone.color)
            .frame(width: width)
    }

    @ViewBuilder
    private var dominantLabel: some View {
        if let dominantZone {
            Text(String(localized: "dominant: \(formatDuration(duration(of: dominantZone)))", bundle: .main))
                .font(.system(size: 12))
                .foregroundStyle(SummaryTheme.inkSecondary)
        }
    }

    private func legendRow(zone: HeartRateZone) -> some View {
        let isDominant = zone == dominantZone
        return HStack(spacing: 9) {
            Circle()
                .fill(zone.color)
                .frame(width: 9, height: 9)
            Text(zone.title)
                .font(.system(size: 13, weight: isDominant ? .semibold : .regular))
                .foregroundStyle(isDominant ? SummaryTheme.ink : SummaryTheme.inkSecondary)
            Spacer()
            Text(formatDuration(duration(of: zone)))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(SummaryTheme.ink)
            Text(percentText(of: zone))
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(SummaryTheme.inkTertiary)
                .frame(width: 38, alignment: .trailing)
        }
    }

    /// Training zones in ascending intensity order (resting excluded by design).
    private var trainingZones: [HeartRateZone] {
        HeartRateZone.allCases.filter { $0 != .resting }
    }

    private var totalDuration: TimeInterval {
        trainingZones.reduce(0) { $0 + duration(of: $1) }
    }

    private func duration(of zone: HeartRateZone) -> TimeInterval {
        zoneDistribution[zone] ?? 0
    }

    /// Segment width proportional to dwell time, accounting for inter-segment spacing.
    private func segmentWidth(of zone: HeartRateZone, in totalWidth: CGFloat) -> CGFloat {
        guard totalDuration > 0 else { return 0 }
        let activeCount = trainingZones.filter { duration(of: $0) > 0 }.count
        let spacingTotal = CGFloat(max(0, activeCount - 1)) * 2
        let available = max(0, totalWidth - spacingTotal)
        return available * CGFloat(duration(of: zone) / totalDuration)
    }

    private func percentText(of zone: HeartRateZone) -> String {
        guard totalDuration > 0 else { return "0%" }
        let percent = Int((duration(of: zone) / totalDuration * 100).rounded())
        return "\(percent)%"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Minute chart (mockup R5 — shared)

/// Per-minute HR range bar chart — yStart = minHR, yEnd = maxHR, bar colored
/// by a zone gradient. Shared by ActivityDetails and the Summary screen so both
/// chart identically. Deliberate mockup deviation: the chart stays interactive
/// (scrub + annotation) instead of static bars.
struct HRMinuteRangeChart: View {

    // MARK: - Properties

    let ranges: [HRMinuteRange]
    /// USER max heart rate (age/HealthKit based) — colors classify against it;
    /// the session peak would paint a calm workout red.
    let userMaxHeartRate: Int
    @Binding var selectedMinute: Date?

    // MARK: - Body

    var body: some View {
        chart
    }

    // MARK: - Implementation

    private var chart: some View {
        Chart {
            if let selectedMinute, let selectedRange = selectedRange(for: selectedMinute) {
                ruleMark(at: selectedMinute, range: selectedRange)
            }
            ForEach(ranges) { range in
                minuteBar(range)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXSelection(value: $selectedMinute.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func minuteBar(_ range: HRMinuteRange) -> some ChartContent {
        BarMark(
            x: .value("Minute", range.minute, unit: .minute),
            yStart: .value("HR min", range.minHR),
            // Floor of 2 bpm — a single-sample minute (min == max) would
            // otherwise render a zero-height, invisible bar.
            yEnd: .value("HR max", max(range.maxHR, range.minHR + 2)),
            width: .ratio(0.55)
        )
        .foregroundStyle(barGradient(for: range))
        .opacity(isMinuteSelected(range: range) ? 1.0 : 0.5)
        // Radius ≥ half the bar width → Charts clamps it to a capsule,
        // matching the mockup's slim pill bars.
        .cornerRadius(8)
    }

    // MARK: - Selection (RuleMark + annotation)

    /// Vertical line on the selected minute with a BPM-range popover.
    /// `overflowResolution(.fit(to: .chart))` keeps the annotation inside the
    /// plot area (e.g. selection on the last minutes).
    @ChartContentBuilder
    private func ruleMark(at minute: Date, range: HRMinuteRange) -> some ChartContent {
        RuleMark(x: .value("Selected Minute", minute, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -30)
            .annotation(
                position: .bottomTrailing,
                spacing: 4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                hrAnnotation(range: range)
            }
    }

    private func hrAnnotation(range: HRMinuteRange) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(range.minute, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("\(range.minHR)–\(range.maxHR)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text("bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Selection helpers

    /// `Date == Date` would fail — Charts sends the selected date with ms
    /// precision while `range.minute` is the calendar-minute start. Compare
    /// with `.minute` granularity.
    private func isMinuteSelected(range: HRMinuteRange) -> Bool {
        guard let selectedMinute else { return true }
        return Calendar.current.isDate(range.minute, equalTo: selectedMinute, toGranularity: .minute)
    }

    private func selectedRange(for selectedMinute: Date) -> HRMinuteRange? {
        ranges.first {
            Calendar.current.isDate($0.minute, equalTo: selectedMinute, toGranularity: .minute)
        }
    }

    // MARK: - Gradient color per BPM range

    /// Vertical gradient from the `minHR` zone (bottom) to the `maxHR` zone
    /// (top) — Apple Fitness-style "rainbow" bar reflecting the minute's range.
    private func barGradient(for range: HRMinuteRange) -> LinearGradient {
        LinearGradient(
            colors: [
                zoneColor(for: range.minHR),
                zoneColor(for: range.maxHR)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// Maps a single BPM to its zone color. The shared classifier handles
    /// supra-max readings and a missing maxHR (→ resting/gray).
    private func zoneColor(for bpm: Int) -> Color {
        HeartRateZone.zone(bpm: bpm, maxHR: userMaxHeartRate).color
    }
}

// MARK: - Previews

#Preview("Strefy — karta Summary (makieta R4)") {
    HeartRateZonesSection(
        zoneDistribution: [
            .recovery: 664,      // 11:04 · 17%
            .fatBurning: 1_521,  // 25:21 · 40%
            .aerobic: 810,       // 13:30 · 21%
            .threshold: 580,     //  9:40 · 15%
            .anaerobic: 235,     //  3:55 ·  6%
        ],
        dominantZone: .fatBurning
    )
    .padding(16)
    .background(SummaryTheme.card, in: .rect(cornerRadius: SummaryTheme.cardRadius))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}

#Preview("Wykres minutowy (makieta R5)") {
    let start = Calendar.current.date(bySetting: .second, value: 0, of: Date().addingTimeInterval(-1_800))!
    let ranges: [HRMinuteRange] = (0..<30).map { minute in
        let base = 95 + (minute * 3) % 60
        return HRMinuteRange(
            minute: start.addingTimeInterval(TimeInterval(minute) * 60),
            minHR: base,
            maxHR: base + 14 + (minute % 4) * 3
        )
    }
    return HRMinuteRangeChart(
        ranges: ranges,
        userMaxHeartRate: 190,
        selectedMinute: .constant(nil)
    )
    .padding(16)
    .background(SummaryTheme.card, in: .rect(cornerRadius: SummaryTheme.cardRadius))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
