//
//  PlanSummaryCard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import SharedModels
import SwiftUI

/// Plan card of the Plans list — also used wherever the user picks one of their plans.
struct PlanSummaryCard: View {

    // MARK: - Properties

    let session: TrainingSession
    let onTap: () -> Void

    // MARK: - Body (structure)

    var body: some View {
        GroupBox {
            summary
        } label: {
            cardLabel
        }
        .styledGroupBox()
        .padding(4)
    }

    private var cardLabel: some View {
        VStack {
            headerButton
            Divider()
        }
    }

    private var headerButton: some View {
        Button {
            onTap()
        } label: {
            header
        }
    }

    private var header: some View {
        HStack {
            activityIcon
            headerTitles
            Spacer()
            chevron
        }
    }

    private var headerTitles: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText
            dateText
        }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            statsRow
            Divider()
            exercisesText
        }
        .padding(4)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(title: durationTitle, value: durationText, alignment: .leading)
                .frame(maxWidth: 110)
            statColumn(title: locationTitle, value: session.location.title)
                .frame(maxWidth: 90)
            statColumn(title: typeTitle, value: typesText, isLast: true)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Implementation

    private var activityIcon: some View {
        Image(systemName: session.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 40, height: 40)
    }

    private var titleText: some View {
        Text(session.title)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateText: some View {
        Text(session.date, style: .date)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
    }

    private var exercisesText: some View {
        Text(exercisesLine)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func statColumn(
        title: String,
        value: String,
        alignment: HorizontalAlignment = .center,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))

            if !isLast {
                Divider()
                    .frame(height: 36)
            }
        }
    }

    // MARK: - Text

    private var durationText: String {
        let total = session.plannedTotalMinutes
        return total > 0 ? "~\(total) min" : "–"
    }

    private var typesText: String {
        let types = Array(Set(session.workouts.map { $0.type.displayName }))
        return types.isEmpty ? "–" : types.joined(separator: " · ")
    }

    private var exercisesLine: String {
        var seen = Set<String>()
        let names = session.workouts
            .flatMap { $0.exercises }
            .map { $0.displayName }
            .filter { seen.insert($0).inserted }
        return names.isEmpty ? "–" : names.joined(separator: " · ")
    }

    private let durationTitle = String(localized: "Duration")
    private let locationTitle = String(localized: "Location")
    private let typeTitle = String(localized: "Type")
}
