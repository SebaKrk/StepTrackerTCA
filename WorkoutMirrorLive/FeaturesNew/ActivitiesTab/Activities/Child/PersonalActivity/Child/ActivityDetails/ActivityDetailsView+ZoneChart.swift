//
//  ActivityDetailsView+ZoneChart.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//
//  Per-minute HR range bar chart z gradient color per HeartRateZone — wzorowane 1:1 na
//  `ClassHistoryDetailView.athleteCardChart` z GymRoom (IPAD-00091).
//
//  `send(.X)` jest dostępne w extension'ie bo `@ViewAction(for: ActivityDetailsFeature.self)`
//  jest na głównym `struct ActivityDetailsView` (ActivityDetailsView.swift:14). Macro generuje
//  send method na typie, więc wszystkie extension'y dziedziczą API "za darmo".

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

extension ActivityDetailsView {

    // MARK: - Section (wstrzyknięty w body NAD rozwijalnym zoneDistributionSection)

    /// Range bar chart per minuta — yStart=minHR, yEnd=maxHR. Bar pokolorowany gradientem od
    /// strefy minHR (dół) do strefy maxHR (góra). Renderowany tylko gdy są dane HR
    /// (`store.hrMinuteRanges` non-empty).
    @ViewBuilder
    func hrRangeChartSection() -> some View {
        if !store.hrMinuteRanges.isEmpty {
            GroupBox {
                hrRangeChart
            } label: {
                hrRangeChartLabel
            }
            .styledGroupBox()
        }
    }

    /// Header label tej sekcji — caption + secondary, wzorem `cardLabel(title:icon:)` z głównego
    /// view'a (private file-scoped, nie da się reuse'ować w extension'ie z innego pliku).
    /// Inline'owany żeby uniknąć otwierania access level helper'a na cały module.
    private var hrRangeChartLabel: some View {
        Label(hrRangeChartTitle, systemImage: "chart.xyaxis.line")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    // MARK: - Chart

    private var hrRangeChart: some View {
        Chart {
            if let selectedMinute = store.selectedMinute,
               let selectedRange = selectedRange(for: selectedMinute) {
                ruleMark(at: selectedMinute, range: selectedRange)
            }
            ForEach(store.hrMinuteRanges) { range in
                BarMark(
                    x: .value("Minute", range.minute, unit: .minute),
                    yStart: .value("HR min", range.minHR),
                    yEnd: .value("HR max", range.maxHR),
                    width: .ratio(0.8)
                )
                .foregroundStyle(barGradient(for: range))
                .opacity(isMinuteSelected(range: range) ? 1.0 : 0.5)
                .cornerRadius(3)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXSelection(value: minuteSelectionBinding.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Selection (RuleMark + annotation)

    /// Pionowa linia na wybranej minucie z popoverem BPM range. `overflowResolution(.fit(to: .chart))`
    /// chroni przed wylotem annotation poza obszar wykresu (np. selection na ostatnich minutach).
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

    /// Custom binding routujący scrub przez TCA action. Wzorem `athleteSelectionBinding` z GymRoom.
    private var minuteSelectionBinding: Binding<Date?> {
        Binding(
            get: { store.selectedMinute },
            set: { send(.minuteSelected($0)) }
        )
    }

    /// `Date == Date` zawiedzie — Charts wysyła selectedDate z ms precision, range.minute = start
    /// kalendarzowej minuty. Compare po `.minute` granularity.
    private func isMinuteSelected(range: HRMinuteRange) -> Bool {
        guard let selectedMinute = store.selectedMinute else { return true }
        return Calendar.current.isDate(range.minute, equalTo: selectedMinute, toGranularity: .minute)
    }

    private func selectedRange(for selectedMinute: Date) -> HRMinuteRange? {
        store.hrMinuteRanges.first {
            Calendar.current.isDate($0.minute, equalTo: selectedMinute, toGranularity: .minute)
        }
    }

    // MARK: - Gradient color per BPM range (wzorem GymRoom barGradient)

    /// Vertical gradient od strefy `minHR` (dół) do strefy `maxHR` (góra). Apple Fitness-style
    /// — bar ma "rainbow" effect odzwierciedlający range BPM tej minuty. Range 130-170 →
    /// gradient od green (fatBurning) na dole do orange (threshold) na górze.
    private func barGradient(for range: HRMinuteRange) -> LinearGradient {
        let maxHR = Int(store.maxHeartRate)
        return LinearGradient(
            colors: [
                zoneColor(for: range.minHR, maxHR: maxHR),
                zoneColor(for: range.maxHR, maxHR: maxHR)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// Mapuje pojedynczy BPM na kolor strefy. **Clamp do `[0, 1]`** — peakHR może chwilowo
    /// przekroczyć theoretical maxHR (np. 198 przy maxHR 190 = 1.04). Bez clamp'a anaerobic
    /// (0.9...1.0) nie złapie i wpadnie do `.gray` fallback.
    private func zoneColor(for bpm: Int, maxHR: Int) -> Color {
        guard maxHR > 0 else { return .gray }
        let percent = min(1.0, max(0.0, Double(bpm) / Double(maxHR)))
        return HeartRateZone.allCases.first { $0.percentageRange.contains(percent) }?.color ?? .gray
    }

    // MARK: - Localized strings

    private var hrRangeChartTitle: String {
        String(localized: "Tętno minuta po minucie")
    }
}
