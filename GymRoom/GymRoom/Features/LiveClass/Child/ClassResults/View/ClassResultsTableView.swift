//
//  ClassResultsTableView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 09/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// The ranking `Table` itself — shared between the end-of-class cover
/// (`ClassResultsView`) and the "Points" tab in `ClassHistoryDetailView`.
/// Chrome (navigation, stats banner, Done button) stays with the host screens;
/// this component owns only columns, cells and the sort binding.
struct ClassResultsTableView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ClassResultsFeature>

    /// Hide the table's own system background so a wrapping GroupBox shows through.
    /// The history "Points" tab sets this (table sits in a GroupBox alongside charts);
    /// the end-of-class cover leaves it `false` for the table's normal background.
    var hidesScrollBackground: Bool = false

    // MARK: - Body

    var body: some View {
        Table(store.sortedRows, sortOrder: $store.sortOrder) {
            TableColumn(rankColumnTitle) { row in
                rankCell(row)
            }
            .width(min: 64, max: 84)

            TableColumn(athleteColumnTitle, value: \.nick) { row in
                athleteCell(row)
            }

            TableColumn(pointsColumnTitle, value: \.points) { row in
                pointsCell(row)
            }

            TableColumn(avgHRColumnTitle, value: \.avgHR) { row in
                metricCell("\(row.avgHR)")
            }

            TableColumn(peakHRColumnTitle, value: \.peakHR) { row in
                metricCell("\(row.peakHR)")
            }

            TableColumn(caloriesColumnTitle, value: \.calories) { row in
                metricCell("\(row.calories)")
            }

            TableColumn(timeColumnTitle, value: \.durationMinutes) { row in
                metricCell(durationText(row))
            }
        }
        // In the history tab the table sits in a GroupBox, so hide its own background
        // to show the box fill through. On the end-of-class cover it keeps its normal
        // (system) background — the trainer sees a plain ranking, not a boxed one.
        .scrollContentBackground(hidesScrollBackground ? .hidden : .automatic)
    }

    // MARK: - Cells (implementation)

    /// Medal for the points podium, `#n` below it — rank is the STABLE points
    /// ranking (`pointsRank`), unaffected by the current column sort.
    private func rankCell(_ row: ClassResultsFeature.ResultRow) -> some View {
        Text(rankText(row))
            .font(.body.weight(.semibold))
            .monospacedDigit()
    }

    private func athleteCell(_ row: ClassResultsFeature.ResultRow) -> some View {
        Text(row.nick)
            .font(.body.weight(rank(row) == 1 ? .bold : .regular))
    }

    private func pointsCell(_ row: ClassResultsFeature.ResultRow) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text(row.hasPoints ? "\(row.points)" : "—")
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func metricCell(_ value: String) -> some View {
        Text(value)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }

    // MARK: - Texts (implementation)

    private var rankColumnTitle: String {
        String(localized: "Rank", bundle: .main)
    }

    private var athleteColumnTitle: String {
        String(localized: "Athlete", bundle: .main)
    }

    private var pointsColumnTitle: String {
        String(localized: "Points", bundle: .main)
    }

    private var avgHRColumnTitle: String {
        String(localized: "Avg HR", bundle: .main)
    }

    private var peakHRColumnTitle: String {
        String(localized: "Max HR", bundle: .main)
    }

    private var caloriesColumnTitle: String {
        String(localized: "Calories", bundle: .main)
    }

    private var timeColumnTitle: String {
        String(localized: "Time", bundle: .main)
    }

    private func rank(_ row: ClassResultsFeature.ResultRow) -> Int {
        store.pointsRank[row.id] ?? 0
    }

    private func rankText(_ row: ClassResultsFeature.ResultRow) -> String {
        switch rank(row) {
        case 1: "🥇"
        case 2: "🥈"
        case 3: "🥉"
        case let position: "#\(position)"
        }
    }

    private func durationText(_ row: ClassResultsFeature.ResultRow) -> String {
        String(localized: "\(row.durationMinutes) min", bundle: .main)
    }
}
