//
//  ExerciseDetailView+Chart.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/05/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

extension ExerciseDetailView {

    // MARK: - Weight Progression

    @ViewBuilder
    var weightProgressionContent: some View {
        if store.weightProgression.isEmpty {
            chartEmptyState(
                systemImage: "chart.line.uptrend.xyaxis",
                description: String(localized: "No weight data recorded for this exercise.")
            )
        } else {
            weightProgressionChart
        }
    }

    var weightProgressionChart: some View {
        Chart {
            ForEach(store.weightProgression) { point in
                LineMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Weight"),
                        point.weight
                    )
                )
                .foregroundStyle(store.category.color.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Weight"),
                        point.weight
                    )
                )
                .foregroundStyle(store.category.color)
                .symbolSize(20)
            }

            if let pr = store.pr {
                RuleMark(y: .value("PR", pr))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(String(format: "PR: %.1f kg", pr))
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
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
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
    }

    // MARK: - Volume per Week

    @ViewBuilder
    var volumePerWeekContent: some View {
        if store.weeklyVolume.isEmpty {
            chartEmptyState(
                systemImage: "chart.bar.fill",
                description: String(localized: "No volume data recorded for this exercise.")
            )
        } else {
            volumePerWeekChart
        }
    }

    var volumePerWeekChart: some View {
        Chart {
            ForEach(store.weeklyVolume) { point in
                BarMark(
                    x: .value(
                        String(localized: "Week"),
                        point.week, unit: .weekOfYear
                    ),
                    y: .value(
                        String(localized: "Volume"),
                        point.volume
                    )
                )
                .foregroundStyle(store.category.color.gradient)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let vol = value.as(Double.self) {
                        Text(String(format: "%.0f", vol))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
    }

    // MARK: - HR per Session

    @ViewBuilder
    var hrPerSessionContent: some View {
        if store.hrPerSession.isEmpty {
            chartEmptyState(
                systemImage: "heart.fill",
                description: String(localized: "No heart rate data recorded for this exercise.")
            )
        } else {
            hrPerSessionChart
        }
    }

    var hrPerSessionChart: some View {
        Chart {
            ForEach(store.hrPerSession) { point in
                LineMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Avg HR"),
                        point.avgHR
                    )
                )
                .foregroundStyle(.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Avg HR"),
                        point.avgHR
                    )
                )
                .foregroundStyle(.red)
                .symbolSize(20)
            }

            if let avg = store.avgHR {
                RuleMark(y: .value("Avg", avg))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(String(format: "%.0f bpm avg", avg))
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hr = value.as(Double.self) {
                        Text(String(format: "%.0f", hr))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
    }

    // MARK: - Chart Empty State Helper

    func chartEmptyState(systemImage: String, description: String) -> some View {
        ChartContentUnavailable(
            systemImage: systemImage,
            description: description
        )
        .frame(height: 200)
    }
}
