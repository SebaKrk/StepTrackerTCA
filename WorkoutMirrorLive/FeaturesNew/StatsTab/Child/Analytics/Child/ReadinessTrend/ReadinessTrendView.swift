//
//  ReadinessTrendView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ReadinessTrendFeature.self)
struct ReadinessTrendView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ReadinessTrendFeature>

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
                Text(String(localized: "Training Readiness Trend", bundle: .main))
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
            ForEach([ActivityDateRange.week, .twoWeeks, .month, .threeMonths]) { range in
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
            if let data = store.historyData, !data.isEmpty {
                chartView(data)
                Divider()
                summaryRow
            } else if store.viewState != .loading {
                ChartContentUnavailable(
                    systemImage: "heart.text.clipboard",
                    description: String(localized: "Not enough readiness data for this period.", bundle: .main)
                )
                .frame(height: 200)
            }
        }
    }

    // MARK: - Chart

    private func chartView(_ data: [TrainingReadinessResult]) -> some View {
        Chart {
            // Background zone bands
            ForEach(ReadinessLevel.allCases, id: \.self) { level in
                RectangleMark(
                    yStart: .value("Min", level.range.lowerBound),
                    yEnd: .value("Max", level.range.upperBound)
                )
                .foregroundStyle(level.color.opacity(0.1))
            }

            // Data line
            ForEach(data, id: \.calculatedAt) { result in
                let isSelected = store.selectedDataPoint == nil || result.calculatedAt == store.selectedDataPoint?.calculatedAt
                LineMark(
                    x: .value("Date", result.calculatedAt),
                    y: .value("Score", result.overallScore)
                )
                .foregroundStyle(.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .opacity(isSelected ? 1.0 : 0.3)

                PointMark(
                    x: .value("Date", result.calculatedAt),
                    y: .value("Score", result.overallScore)
                )
                .foregroundStyle(result.readinessLevel.color)
                .symbolSize(30)
                .opacity(isSelected ? 1.0 : 0.3)
            }

            if let selected = store.selectedDataPoint {
                RuleMark(x: .value("Selected", selected.calculatedAt))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .offset(y: -10)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        annotationPopup(score: selected.overallScore, level: selected.readinessLevel)
                    }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartScrollableAxes(store.dateRange.rawValue > 28 ? .horizontal : [])
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        .chartXSelection(value: Binding(
            get: { store.selectedDataPoint?.calculatedAt },
            set: { date in
                guard let date else {
                    send(.dataPointSelected(nil))
                    return
                }
                let closest = data.min(by: {
                    abs($0.calculatedAt.timeIntervalSince(date)) < abs($1.calculatedAt.timeIntervalSince(date))
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
        .frame(height: 200)
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Average", bundle: .main))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(store.averageScore)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            levelCountsView
        }
    }

    private var levelCountsView: some View {
        HStack(spacing: 12) {
            ForEach([ReadinessLevel.excellent, .good, .fair, .poor, .veryPoor], id: \.self) { level in
                if let count = store.daysPerLevel[level], count > 0 {
                    VStack(spacing: 2) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 8, height: 8)
                        Text("\(count)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}
