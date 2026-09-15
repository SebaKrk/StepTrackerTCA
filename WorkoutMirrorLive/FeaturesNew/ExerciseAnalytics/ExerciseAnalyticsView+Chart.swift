//
//  ExerciseAnalyticsView+Chart.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/05/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

extension ExerciseAnalyticsView {

    @ViewBuilder
    var movementBalanceContent: some View {
        if store.exerciseLogs.isEmpty {
            movementBalanceEmpty
        } else {
            VStack(spacing: 12) {
                movementBalanceChart
                Divider()
                categoryLegend
            }
        }
    }

    var movementBalanceEmpty: some View {
        ChartContentUnavailable(
            systemImage: "figure.mixed.cardio",
            description: String(localized: "No exercise data for this month.")
        )
        // Same empty height as the exercise-list card below — empty GroupBoxes
        // on this screen read as one system, not two different voids.
        .frame(height: 200)
    }

    var movementBalanceChart: some View {
        Chart {
            ForEach(Array(store.weeklyBreakdown.enumerated()), id: \.offset) { weekIndex, breakdown in
                ForEach(MovementCategory.allCases, id: \.self) { category in
                    if let count = breakdown[category], count > 0 {
                        BarMark(
                            x: .value(
                                String(localized: "Week"),
                                "W\(weekIndex + 1)"
                            ),
                            y: .value(
                                String(localized: "Count"),
                                count
                            )
                        )
                        .foregroundStyle(category.color)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.mask(alignment: .bottom) {
                Rectangle()
                    .scaleEffect(y: store.isChartAnimated ? 1 : 0, anchor: .bottom)
            }
        }
        .animation(.smooth(duration: 0.6), value: store.isChartAnimated)
        .frame(height: 200)
    }

    var categoryLegend: some View {
        let totalCount = store.categoryBreakdown.values.reduce(0, +)

        return VStack(spacing: 6) {
            ForEach(MovementCategory.allCases, id: \.self) { category in
                if let count = store.categoryBreakdown[category], count > 0 {
                    categoryLegendRow(category: category, count: count, total: totalCount)
                }
            }
        }
    }

    func categoryLegendRow(category: MovementCategory, count: Int, total: Int) -> some View {
        let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0

        return HStack(spacing: 8) {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            Text(category.displayName)
                .font(.caption)
            Spacer()
            Text("\(Int(percentage))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
