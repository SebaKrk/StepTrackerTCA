//
//  HealthMetricsTrendView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/04/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: HealthMetricsTrendFeature.self)
struct HealthMetricsTrendView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<HealthMetricsTrendFeature>

    // MARK: - Body

    var body: some View {
        GroupBox {
            contentView
                .subscriptionOverlay(
                    contentState: store.contentState,
                    subscriptionTier: store.subscriptionTier,
                    requiredTier: store.requiredTier
                )
        } label: {
            headerView
        }
        .styledGroupBox()
        .onAppear {
            send(.viewDidAppear)
        }
        .skeleton(isLoading: store.viewState == .loading)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack {
            HStack {
                Text(String(localized: "Health Metrics Trends", bundle: .main))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                dateRangeMenu
            }
            Divider()
        }
    }

    private var dateRangeMenu: some View {
        Menu {
            ForEach(ActivityDateRange.allCases) { range in
                Button {
                    send(.dateRangeChanged(range))
                } label: {
                    if range == store.dateRange {
                        Label(range.title, systemImage: "checkmark")
                    } else {
                        Text(range.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(store.dateRange.title)
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 8) {
            metricPicker
            Group {
                if let data = store.currentData {
                    VStack(spacing: 8) {
                        chartArea(data)
                        Divider()   
                        summaryRow(data)
                    }
                } else if store.viewState == .loading {
                    Color.clear
                } else {
                    ChartContentUnavailable(
                        systemImage: store.selectedMetric.icon,
                        description: store.selectedMetric.missingDataMessage
                    )
                }
            }
            .frame(height: 230)
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        HStack(spacing: 6) {
            ForEach(HealthMetricType.allCases) { metric in
                Button {
                    send(.metricSelected(metric))
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: metric.icon)
                        Text(metric.title)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        store.selectedMetric == metric
                            ? Color.accentColor.opacity(0.15)
                            : Color.secondary.opacity(0.08),
                        in: .capsule
                    )
                    .foregroundStyle(store.selectedMetric == metric ? .primary : .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chart Area

    @ViewBuilder
    private func chartArea(_ data: [HistoricalDataPoint]) -> some View {
        switch store.selectedMetric {
        case .rhr, .hrv:
            lineChart(data)
            lineChartLegend
        case .sleep:
            sleepBarChart(data)
            sleepLegend
        case .activity:
            activityBarChart(data)
        }
    }

    // MARK: - Line Chart (RHR / HRV)

    private func lineChart(_ data: [HistoricalDataPoint]) -> some View {
        Chart {
            ForEach(data) { point in
                let isSelected = store.selectedDataPoint == nil || point.date == store.selectedDataPoint?.date
                dataLineMark(point: point)
                    .opacity(isSelected ? 1.0 : 0.3)
                dataPointMark(point: point)
                    .opacity(isSelected ? 1.0 : 0.3)
            }
            ForEach(store.rollingAverage) { point in
                avgLineMark(point: point)
                    .opacity(store.selectedDataPoint == nil ? 1.0 : 0.3)
            }
            if let selected = store.selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .offset(y: -10)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        annotationPopup(
                            value: formattedValue(selected.value),
                            date: selected.date
                        )
                    }
            }
        }
        .chartYScale(domain: yDomain(for: data))
        .chartYAxis {
            AxisMarks(values: .stride(by: strideStep(for: data))) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(format: "%.0f", v))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(
                values: store.dateRange.rawValue <= 7
                    ? .stride(by: .day, roundLowerBound: false, roundUpperBound: false)
                    : .automatic(desiredCount: 7)
            ) { _ in
                AxisValueLabel(
                    format: store.dateRange.rawValue <= 7
                        ? .dateTime.day(.twoDigits)
                        : .dateTime.month(.abbreviated).day()
                )
            }
        }
        .chartXScale(range: .plotDimension(startPadding: 8, endPadding: 24))
        .chartPlotStyle { plot in
            plot.mask(alignment: .leading) {
                Rectangle()
                    .scaleEffect(x: store.isChartAnimated ? 1 : 0, anchor: .leading)
            }
        }
        .chartScrollableAxes(store.dateRange.rawValue > 28 ? .horizontal : [])
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        .chartXSelection(value: Binding(
            get: { store.selectedDataPoint?.date },
            set: { newDate in
                guard let newDate else { send(.dataPointSelected(nil)); return }
                send(.dataPointSelected(data.closestPoint(to: newDate)))
            }
        ))
        .animation(.easeInOut(duration: 0.8), value: store.isChartAnimated)
        .frame(height: 180)
    }

    private var lineChartLegend: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle().fill(.blue).frame(width: 6, height: 6)
                Text(store.selectedMetric.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Capsule().fill(.orange.opacity(0.8)).frame(width: 16, height: 3)
                Text(String(localized: "7-day avg", bundle: .main))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Sleep Bar Chart

    private func sleepBarChart(_ data: [HistoricalDataPoint]) -> some View {
        Chart {
            ForEach(data) { point in
                sleepBarMark(point: point)
                    .opacity(store.selectedDataPoint == nil || point.date == store.selectedDataPoint?.date ? 1.0 : 0.3)
            }
            sleepTargetRuleMark()
            if let selected = store.selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .offset(y: -10)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        annotationPopup(
                            value: formattedValue(selected.value),
                            date: selected.date
                        )
                    }
            }
        }
        .chartYScale(domain: 0...12)
        .chartYAxis {
            AxisMarks(values: [0, 4, 6, 7, 8, 10]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(format: "%.0fh", v))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(
                values: store.dateRange.rawValue <= 7
                    ? .stride(by: .day, roundLowerBound: false, roundUpperBound: false)
                    : .automatic(desiredCount: 7)
            ) { _ in
                AxisValueLabel(
                    format: store.dateRange.rawValue <= 7
                        ? .dateTime.day(.twoDigits)
                        : .dateTime.month(.abbreviated).day()
                )
            }
        }
        .chartXScale(range: .plotDimension(startPadding: 8, endPadding: 24))
        .chartPlotStyle { plot in
            plot.mask(alignment: .bottom) {
                Rectangle()
                    .scaleEffect(y: store.isChartAnimated ? 1 : 0, anchor: .bottom)
            }
        }
        .animation(.smooth(duration: 0.6), value: store.isChartAnimated)
        .chartScrollableAxes(store.dateRange.rawValue > 28 ? .horizontal : [])
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        .chartXSelection(value: Binding(
            get: { store.selectedDataPoint?.date },
            set: { newDate in
                guard let newDate else { send(.dataPointSelected(nil)); return }
                send(.dataPointSelected(data.closestPoint(to: newDate)))
            }
        ))
        .frame(height: 180)
    }

    private var sleepLegend: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2).fill(.green).frame(width: 10, height: 10)
                Text("≥7h").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2).fill(.orange).frame(width: 10, height: 10)
                Text("6–7h").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2).fill(.red).frame(width: 10, height: 10)
                Text("<6h").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Activity Bar Chart

    private func activityBarChart(_ data: [HistoricalDataPoint]) -> some View {
        let avg = data.reduce(0.0) { $0 + $1.value } / Double(data.count)
        let segments = store.activitySegments ?? []
        let names = uniqueActivityNames(from: segments)
        let colors = uniqueActivityColors(from: segments)

        return Chart {
            if segments.isEmpty {
                // Fallback: słupki jednokolorowe gdy segmenty jeszcze ładują
                ForEach(data) { point in
                    activityBarMark(point: point)
                }
            } else {
                ForEach(segments) { segment in
                    BarMark(
                        x: .value("Date", segment.date, unit: .day),
                        y: .value("kcal", segment.kcal)
                    )
                    .foregroundStyle(by: .value("Activity", segment.activityName))
                    .cornerRadius(2)
                    .opacity(store.selectedDataPoint == nil || Calendar.current.isDate(segment.date, inSameDayAs: store.selectedDataPoint?.date ?? .distantPast) ? 1.0 : 0.3)
                }
            }
            activityAverageRuleMark(avg: avg)
            if let selected = store.selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .offset(y: -10)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        annotationPopup(
                            value: formattedValue(selected.value),
                            date: selected.date
                        )
                    }
            }
        }
        .chartForegroundStyleScale(
            domain: names,
            range: colors
        )
        .chartLegend(position: .bottom, spacing: 8)
        .chartYScale(domain: activityYDomain(for: data))
        .chartYAxis {
            AxisMarks(values: .stride(by: activityStrideStep(for: data))) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(format: "%.0f", v))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(
                values: store.dateRange.rawValue <= 7
                    ? .stride(by: .day, roundLowerBound: false, roundUpperBound: false)
                    : .automatic(desiredCount: 7)
            ) { _ in
                AxisValueLabel(
                    format: store.dateRange.rawValue <= 7
                        ? .dateTime.day(.twoDigits)
                        : .dateTime.month(.abbreviated).day()
                )
            }
        }
        .chartXScale(range: .plotDimension(startPadding: 8, endPadding: 24))
        .chartPlotStyle { plot in
            plot.mask(alignment: .bottom) {
                Rectangle()
                    .scaleEffect(y: store.isChartAnimated ? 1 : 0, anchor: .bottom)
            }
        }
        .animation(.smooth(duration: 0.6), value: store.isChartAnimated)
        .chartScrollableAxes(store.dateRange.rawValue > 28 ? .horizontal : [])
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        .chartXSelection(value: Binding(
            get: { store.selectedDataPoint?.date },
            set: { newDate in
                guard let newDate else { send(.dataPointSelected(nil)); return }
                send(.dataPointSelected(data.closestPoint(to: newDate)))
            }
        ))
        .frame(height: 180)
    }

    // MARK: - Summary

    private func summaryRow(_ data: [HistoricalDataPoint]) -> some View {
        HStack {
            if let avg = store.average {
                summaryMetric(
                    title: String(localized: "Average", bundle: .main),
                    value: formattedValue(avg)
                )
            }
            Divider()
            if let latest = data.last {
                summaryMetric(
                    title: String(localized: "Latest", bundle: .main),
                    value: formattedValue(latest.value)
                )
            }
            Divider()
            summaryMetric(
                title: String(localized: "Entries", bundle: .main),
                value: "\(data.count)"
            )
        }
        .font(.caption)
    }

    private func summaryMetric(title: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Collection Helper

private extension Array where Element == HistoricalDataPoint {
    func closestPoint(to date: Date) -> HistoricalDataPoint? {
        self.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}
