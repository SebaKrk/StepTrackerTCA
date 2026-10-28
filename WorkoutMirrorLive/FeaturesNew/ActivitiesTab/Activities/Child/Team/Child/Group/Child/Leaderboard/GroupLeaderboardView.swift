//
//  GroupLeaderboardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Content of the leaderboard card on the group screen.
@ViewAction(for: GroupLeaderboardFeature.self)
struct GroupLeaderboardView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GroupLeaderboardFeature>

    // Fits ContentUnavailableView (about three rows), so empty, loading and filled states keep the card's height.
    @ScaledMetric(relativeTo: .body) private var contentMinHeight: CGFloat = 200

    // MARK: - Body (structure)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Wrapped, so the min height applies to the list as a whole, not to every row.
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, minHeight: contentMinHeight, alignment: .top)
            if store.range == .week, store.viewState == .success, !store.weekRows.isEmpty {
                Divider()
                weekNote
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: contentMinHeight)
        case .failed:
            emptyState(title: failedTitle, systemImage: "exclamationmark.triangle", description: failedText)
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
            emptyState(title: noResultsTitle, systemImage: "list.number", description: noResultsText)
        } else {
            ForEach(store.dayRows) { row in
                dayRow(row)
                if row.id != store.dayRows.last?.id {
                    Divider()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var weekRows: some View {
        if store.weekRows.isEmpty {
            emptyState(title: noResultsTitle, systemImage: "calendar", description: noWeekResultsText)
        } else {
            ForEach(store.weekRows) { row in
                weekRow(row)
                if row.id != store.weekRows.last?.id {
                    Divider()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var weekNote: some View {
        Text("\(weekCaption) \(kcalNoteText)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Implementation

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        // Smaller than the full-screen default — it sits inside a card.
        ContentUnavailableView {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: systemImage)
            }
            .imageScale(.small)
        } description: {
            Text(description)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, minHeight: contentMinHeight)
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
            valueText(for: row)
        }
        .foregroundStyle(row.isMe ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }

    private func weekRow(_ row: TeamWeekRow) -> some View {
        HStack(spacing: 12) {
            placeLabel(row.place)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .fontWeight(row.isMe ? .bold : .regular)
                Text(String(localized: "\(row.workouts) workouts"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(localized: "\(row.points) pts"))
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                Text(row.kcal.map { "\($0) kcal" } ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(row.isMe ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }

    private func placeLabel(_ place: Int?) -> some View {
        Text(place.map { "\($0)" } ?? "–")
            .font(.headline)
            .monospacedDigit()
            .frame(width: 24)
            .foregroundStyle(.secondary)
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

    // Rows without a place show their value muted, so "No result" never reads like a score.
    private func valueText(for row: TeamLeaderboardRow) -> some View {
        Text(value(for: row))
            .font(row.place == nil ? .subheadline : .body.weight(.bold))
            .foregroundStyle(valueStyle(for: row))
            .monospacedDigit()
    }

    private func valueStyle(for row: TeamLeaderboardRow) -> AnyShapeStyle {
        if row.place == nil { return AnyShapeStyle(.secondary) }
        return row.isMe ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary)
    }

    private func value(for row: TeamLeaderboardRow) -> String {
        if let score = row.score {
            return score.displayText
        }
        return row.entry.effortPoints.map { String(localized: "\($0) pts") } ?? "—"
    }

    // MARK: - Text

    private let noResultsTitle = String(localized: "No Results Yet")
    private let noResultsText = String(localized: "Results show up once members send a workout to the group.")
    private let failedTitle = String(localized: "Something went wrong")
    private let noWeekResultsText = String(localized: "No results this week yet.")
    private let weekCaption = String(localized: "Effort points and kcal summed Monday to Sunday — every workout counts.")
    private let kcalNoteText = String(localized: "kcal only from members who share them.")
    private let failedText = String(localized: "Couldn't load the leaderboard.")
    private let warmStartBadge = String(localized: "started warm")
    private let editedBadge = String(localized: "edited")
    private let lateBadge = String(localized: "late")
}
