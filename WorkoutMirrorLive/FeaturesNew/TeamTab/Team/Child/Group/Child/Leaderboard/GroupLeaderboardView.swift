//
//  GroupLeaderboardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Rows of the leaderboard section; the group screen puts them in a `List` section.
@ViewAction(for: GroupLeaderboardFeature.self)
struct GroupLeaderboardView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GroupLeaderboardFeature>

    // MARK: - Body (structure)

    var body: some View {
        Group {
            pickers
            content
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .failed:
            Text(failedText)
                .foregroundStyle(.secondary)
        case .success:
            switch store.range {
            case .day:
                dayRows
            case .week:
                weekRows
            }
        }
    }

    @ViewBuilder
    private var dayRows: some View {
        if store.dayRows.isEmpty {
            Text(noResultsText)
                .foregroundStyle(.secondary)
        } else {
            ForEach(store.dayRows) { row in
                dayRow(row)
            }
        }
    }

    @ViewBuilder
    private var weekRows: some View {
        if store.weekRows.isEmpty {
            Text(noWeekResultsText)
                .foregroundStyle(.secondary)
        } else {
            ForEach(store.weekRows) { row in
                weekRow(row)
            }
            Text(weekRuleText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Implementation

    private var pickers: some View {
        VStack(spacing: 8) {
            Picker(rangeTitle, selection: $store.range.sending(\.view.rangeChanged)) {
                ForEach(TeamLeaderboardRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            HStack(spacing: 8) {
                Picker(lensTitle, selection: $store.lens.sending(\.view.lensChanged)) {
                    Text(scoreTitle).tag(TeamLeaderboardLens.score)
                    Text(effortTitle).tag(TeamLeaderboardLens.effort)
                }
                Picker(divisionTitle, selection: $store.division.sending(\.view.divisionChanged)) {
                    Text(rxTitle).tag(BoardDivision.rx)
                    Text(scaledTitle).tag(BoardDivision.scaled)
                }
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }

    private func dayRow(_ row: TeamLeaderboardRow) -> some View {
        HStack(spacing: 12) {
            placeLabel(row.place)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.entry.displayName)
                    .fontWeight(row.isMe ? .bold : .regular)
                badges(row.entry)
            }
            Spacer()
            Text(value(for: row.entry))
                .font(.body.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(row.isMe ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }

    private func weekRow(_ row: TeamWeekRow) -> some View {
        HStack(spacing: 12) {
            placeLabel(row.place)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .fontWeight(row.isMe ? .bold : .regular)
                Text(dayPlaces(row))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(row.total)")
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                Text(String(localized: "\(row.workouts) workouts"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(row.isMe ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }

    private func placeLabel(_ place: Int?) -> some View {
        Text(place.map { "\($0)" } ?? "·")
            .font(.headline)
            .monospacedDigit()
            .frame(width: 24)
            .foregroundStyle(place == 1 ? AnyShapeStyle(.yellow) : AnyShapeStyle(.secondary))
    }

    @ViewBuilder
    private func badges(_ entry: TeamEntry) -> some View {
        let labels = badgeLabels(entry)
        if !labels.isEmpty {
            Text(labels.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func badgeLabels(_ entry: TeamEntry) -> [String] {
        var labels: [String] = []
        if let kcal = entry.kcal {
            labels.append("\(Int(kcal.rounded())) kcal")
        }
        if entry.hrVerified {
            labels.append(hrBadge)
        }
        if let planMinutes = store.planMinutes, entry.measuredMinutes * 10 < planMinutes * 9 {
            labels.append(String(localized: "measured \(entry.measuredMinutes)/\(planMinutes) min"))
        }
        if entry.startedAfterActivity {
            labels.append(warmStartBadge)
        }
        if entry.editedAt != nil {
            labels.append(editedBadge)
        }
        if entry.isLate {
            labels.append(lateBadge)
        }
        return labels
    }

    private func value(for entry: TeamEntry) -> String {
        switch store.lens {
        case .score:
            return entry.score.displayText
        case .effort:
            return entry.effortPoints.map { String(localized: "\($0) pts") } ?? "—"
        }
    }

    private func dayPlaces(_ row: TeamWeekRow) -> String {
        store.weekDays
            .filter { row.placesByDay[$0] != nil || row.missingDays.contains($0) }
            .map { day in row.placesByDay[day].map { "\($0)" } ?? "–" }
            .joined(separator: " · ")
    }

    // MARK: - Text

    private let rangeTitle = String(localized: "Period")
    private let lensTitle = String(localized: "Rank by")
    private let scoreTitle = String(localized: "Score")
    private let effortTitle = String(localized: "Effort")
    private let divisionTitle = String(localized: "Division")
    private let rxTitle = String(localized: "Rx")
    private let scaledTitle = String(localized: "Scaled")
    private let noResultsText = String(localized: "No results yet today.")
    private let noWeekResultsText = String(localized: "No results this week yet.")
    private let weekRuleText = String(localized: "Sum of daily places — lower is better. A missed day counts as last place + 1; ties go to more workouts.")
    private let failedText = String(localized: "Couldn't load the leaderboard.")
    private let hrBadge = String(localized: "✓ HR")
    private let warmStartBadge = String(localized: "started warm")
    private let editedBadge = String(localized: "edited")
    private let lateBadge = String(localized: "late")
}
