//
//  WorkoutVolumeView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutVolumeFeature.self)
struct WorkoutVolumeView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutVolumeFeature>

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
                Text(String(localized: "Workout Volume", bundle: .main))
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
            if let data = store.weeklyData, !data.isEmpty {
                chartView(data)
                Divider()
                summaryRow
            } else if store.viewState != .loading {
                ChartContentUnavailable(
                    systemImage: "figure.run",
                    description: String(localized: "No workout data available for this period.", bundle: .main)
                )
                .frame(height: 200)
            }
        }
    }

    // MARK: - Chart

    private func chartView(_ data: [WorkoutVolumeFeature.WeeklyActivitySegment]) -> some View {
        let weekCount = Set(data.map(\.weekStart)).count

        return Chart(data) { segment in
            BarMark(
                x: .value("Week", segment.weekStart, unit: .weekOfYear),
                y: .value("Minutes", segment.durationMinutes)
            )
            .foregroundStyle(by: .value("Activity", segment.activityName))
            .cornerRadius(4)
        }
        .chartForegroundStyleScale(
            domain: uniqueActivityNames(from: data),
            range: uniqueActivityColors(from: data)
        )
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text(formatMinutesAxis(minutes))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartScrollableAxes(weekCount > 6 ? .horizontal : [])
        .chartXVisibleDomain(length: 6 * 7 * 24 * 3600)
        .chartScrollPosition(initialX: Calendar.current.date(byAdding: .weekOfYear, value: -6, to: Date()) ?? Date())
        .chartLegend(position: .bottom, spacing: 8)
        .chartPlotStyle { plot in
            plot.mask(alignment: .bottom) {
                Rectangle()
                    .scaleEffect(y: store.isChartAnimated ? 1 : 0, anchor: .bottom)
            }
        }
        .animation(.smooth(duration: 0.6), value: store.isChartAnimated)
        .frame(height: 180)
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack {
            summaryMetric(
                title: String(localized: "Total", bundle: .main),
                value: "\(store.totalWorkouts)",
                unit: String(localized: "workouts", bundle: .main)
            )
            Divider()
            summaryMetric(
                title: String(localized: "Time", bundle: .main),
                value: formatMinutes(store.totalDurationMinutes),
                unit: String(localized: "total", bundle: .main)
            )
            Divider()
            summaryMetric(
                title: String(localized: "Avg", bundle: .main),
                value: formatMinutes(store.averageDurationMinutes),
                unit: String(localized: "per workout", bundle: .main)
            )
        }
        .font(.caption)
    }

    private func summaryMetric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(unit)
                .foregroundStyle(.secondary)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
