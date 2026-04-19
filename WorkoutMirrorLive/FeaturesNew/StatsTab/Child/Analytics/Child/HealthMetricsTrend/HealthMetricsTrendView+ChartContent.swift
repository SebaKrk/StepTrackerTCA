//
//  HealthMetricsTrendView+ChartContent.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

extension HealthMetricsTrendView {

    // MARK: - Line Marks

    func dataLineMark(point: HistoricalDataPoint) -> some ChartContent {
        LineMark(
            x: .value("Date", point.date),
            y: .value("Value", point.value)
        )
        .foregroundStyle(Color.blue.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1))
    }

    func dataPointMark(point: HistoricalDataPoint) -> some ChartContent {
        PointMark(
            x: .value("Date", point.date),
            y: .value("Value", point.value)
        )
        .foregroundStyle(Color.blue)
        .symbolSize(20)
    }

    func avgLineMark(point: HistoricalDataPoint) -> some ChartContent {
        LineMark(
            x: .value("Date", point.date),
            y: .value("7d avg", point.value),
            series: .value("Series", "avg")
        )
        .foregroundStyle(Color.orange.opacity(0.8))
        .lineStyle(StrokeStyle(lineWidth: 2))
        .interpolationMethod(.catmullRom)
    }

    // MARK: - Bar Marks

    func sleepBarMark(point: HistoricalDataPoint) -> some ChartContent {
        BarMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Hours", point.value)
        )
        .foregroundStyle(sleepColor(hours: point.value))
        .cornerRadius(3)
    }

    func sleepTargetRuleMark() -> some ChartContent {
        RuleMark(y: .value("Target", 7.0))
            .foregroundStyle(Color.green.opacity(0.4))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .annotation(position: .top, alignment: .leading) {
                Text("7h")
                    .font(.caption2)
                    .foregroundStyle(Color.green)
            }
    }

    func activityBarMark(point: HistoricalDataPoint) -> some ChartContent {
        BarMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("kcal", point.value)
        )
        .foregroundStyle(Color.orange.opacity(0.7))
        .cornerRadius(3)
    }

    // MARK: - Activity Segment Helpers

    func uniqueActivityNames(from segments: [HealthMetricsTrendFeature.DailyActivitySegment]) -> [String] {
        var seen: Set<String> = []
        var names: [String] = []
        for segment in segments {
            if seen.insert(segment.activityName).inserted {
                names.append(segment.activityName)
            }
        }
        return names
    }

    func uniqueActivityColors(from segments: [HealthMetricsTrendFeature.DailyActivitySegment]) -> [Color] {
        var seen: Set<String> = []
        var colors: [Color] = []
        for segment in segments {
            if seen.insert(segment.activityName).inserted {
                colors.append(segment.activityColor)
            }
        }
        return colors
    }

    func activityAverageRuleMark(avg: Double) -> some ChartContent {
        RuleMark(y: .value("Average", avg))
            .foregroundStyle(Color.primary.opacity(0.8))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
            .annotation(position: .top, alignment: .leading) {
                Text(String(format: "%.0f kcal avg", avg))
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
            }
    }

    // MARK: - Selection Rule Mark

    /// RuleMark zaznaczenia punktu z annotacją.
    /// overflowResolution(y: .disabled) pozwala annotacji wylewać się poza górę wykresu
    /// bez zmiany layoutu — zastępuje chartPlotStyle(.padding(.top:)).
    func selectionRuleMark<Content: View>(
        for point: HistoricalDataPoint,
        @ViewBuilder annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected", point.date))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .offset(y: -10)
            .annotation(
                position: .top,
                spacing: 0,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                annotationView()
            }
    }

    // MARK: - Annotation Popup View

    func annotationPopup(value: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }

    // MARK: - Y Scale Helpers

    /// Domena Y dla line chartu — tight fit z 15% paddingiem, nie zaczyna od zera.
    func yDomain(for data: [HistoricalDataPoint]) -> ClosedRange<Double> {
        guard let minV = data.map(\.value).min(),
              let maxV = data.map(\.value).max() else {
            return 0...100
        }
        let padding = max((maxV - minV) * 0.15, 1.0)
        return (minV - padding)...(maxV + padding)
    }

    /// Domena Y dla bar chartu aktywności — zawsze zaczyna od 0.
    func activityYDomain(for data: [HistoricalDataPoint]) -> ClosedRange<Double> {
        guard let maxV = data.map(\.value).max(), maxV > 0 else { return 0...500 }
        return 0...(maxV * 1.15)
    }

    /// Domena Y dla bar chartu aktywności z dodatkowym headroomem na annotation popup (~35%).
    func activityYDomainWithHeadroom(for data: [HistoricalDataPoint]) -> ClosedRange<Double> {
        guard let maxV = data.map(\.value).max(), maxV > 0 else { return 0...500 }
        return 0...(maxV * 1.40)
    }

    /// Krok osi Y obliczony algorytmem "nice numbers" (~3–5 podziałek).
    /// .stride(by:) zamiast .automatic — .automatic ignoruje chartYScale gdy chart ma wiele series.
    func strideStep(for data: [HistoricalDataPoint]) -> Double {
        guard let minV = data.map(\.value).min(),
              let maxV = data.map(\.value).max(),
              maxV > minV else { return 10 }
        let rawStep = (maxV - minV) / 3.0
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude
        let niceStep: Double
        if normalized < 1.5 { niceStep = 1 }
        else if normalized < 3.5 { niceStep = 2 }
        else if normalized < 7.5 { niceStep = 5 }
        else { niceStep = 10 }
        return niceStep * magnitude
    }

    // MARK: - Formatting Helpers

    func formattedValue(_ value: Double) -> String {
        switch store.selectedMetric {
        case .rhr: return String(format: "%.0f bpm", value)
        case .hrv: return String(format: "%.0f ms", value)
        case .sleep: return String(format: "%.1f h", value)
        case .activity: return String(format: "%.0f kcal", value)
        }
    }

    func sleepColor(hours: Double) -> Color {
        if hours >= 7.0 { return .green }
        if hours >= 6.0 { return .orange }
        return .red
    }
}
