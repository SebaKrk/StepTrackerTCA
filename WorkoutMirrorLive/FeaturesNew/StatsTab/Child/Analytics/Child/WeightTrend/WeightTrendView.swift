//
//  WeightTrendView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WeightTrendFeature.self)
struct WeightTrendView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WeightTrendFeature>

    // MARK: - Body

    var body: some View {
        GroupBox {
            contentView
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
                Text(String(localized: "Weight Trend", bundle: .main))
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
            if let data = store.weightData, !data.isEmpty {
                chartView(data)
                Divider()
                summaryRow(data)
            } else if store.viewState != .loading {
                ChartContentUnavailable(
                    systemImage: "scalemass",
                    description: String(localized: "No weight measurements found for this period.", bundle: .main)
                )
                .frame(height: 200)
            }
        }
    }

    // MARK: - Chart

    private func chartView(_ data: [WeightTrendFeature.WeightDataPoint]) -> some View {
        Chart {
            ForEach(data) { point in
                let isSelected = store.selectedDataPoint == nil || point.date == store.selectedDataPoint?.date
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .opacity(isSelected ? 1.0 : 0.3)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
                .symbolSize(20)
                .opacity(isSelected ? 1.0 : 0.3)
            }

            // Average line
            let avg = data.reduce(0.0) { $0 + $1.weight } / Double(data.count)
            RuleMark(y: .value("Average", avg))
                .foregroundStyle(Color.primary.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
                .annotation(
                    position: .top,
                    alignment: .leading,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    Text(String(format: "%.1f kg avg", avg))
                        .font(.caption2.bold())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
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
                        annotationPopup(value: String(format: "%.1f kg", selected.weight), date: selected.date)
                    }
            }
        }
        .chartYScale(domain: yDomain(for: data))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let kg = value.as(Double.self) {
                        Text(String(format: "%.0f", kg))
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
        .chartScrollableAxes(store.dateRange.rawValue > 28 ? .horizontal : [])
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        .chartXSelection(value: Binding(
            get: { store.selectedDataPoint?.date },
            set: { date in
                guard let date else {
                    send(.dataPointSelected(nil))
                    return
                }
                let closest = data.min(by: {
                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                })
                send(.dataPointSelected(closest))
            }
        ))
        .chartPlotStyle { plot in
            plot.mask(alignment: .leading) {
                Rectangle()
                    .scaleEffect(x: store.isChartAnimated ? 1 : 0, anchor: .leading)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: store.isChartAnimated)
        .frame(height: 180)
    }

    // MARK: - Summary

    private func summaryRow(_ data: [WeightTrendFeature.WeightDataPoint]) -> some View {
        HStack {
            if let current = data.last {
                summaryMetric(
                    title: String(localized: "Current", bundle: .main),
                    value: String(format: "%.1f kg", current.weight)
                )
            }
            Divider()
            if let change = store.weightChange {
                summaryMetric(
                    title: String(localized: "Change", bundle: .main),
                    value: String(format: "%+.1f kg", change),
                    color: change < 0 ? .green : (change > 0 ? .orange : .primary)
                )
            }
            Divider()
            if let first = data.first {
                summaryMetric(
                    title: String(localized: "Start", bundle: .main),
                    value: String(format: "%.1f kg", first.weight)
                )
            }
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
