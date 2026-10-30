//
//  TeamGroupCard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import SharedModels
import SwiftUI

/// Group card of the Team list — same build as the plan card: header, divider, three columns.
struct TeamGroupCard: View {

    // MARK: - Properties

    let group: TeamGroup
    let isMine: Bool
    let today: String
    let myEntry: TeamEntry?
    let onTap: () -> Void

    // MARK: - Body (structure)

    var body: some View {
        Button(action: onTap) {
            card
        }
        .buttonStyle(.plain)
    }

    private var card: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                dayContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .styledGroupBox()
    }

    private var header: some View {
        HStack(spacing: 12) {
            groupIcon
            titles
            Spacer(minLength: 0)
            chevron
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(group.name)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var dayContent: some View {
        if let plan = todayPlan {
            statsRow(plan)
        } else {
            noPlanRow
        }
    }

    private func statsRow(_ plan: TeamGroupPlanSummary) -> some View {
        HStack(spacing: 0) {
            statColumn(title: planTitle, value: plan.title, caption: minutesText(plan.sessionMinutes))
            Divider()
                .frame(height: 40)
            resultsColumn(plan)
            Divider()
                .frame(height: 40)
            statColumn(title: yourResultTitle, value: myResultText, caption: myResultCaption)
        }
    }

    private func resultsColumn(_ plan: TeamGroupPlanSummary) -> some View {
        VStack(spacing: 4) {
            Text(resultsTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(resultsText(plan))
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            resultDots(plan)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Implementation

    private var groupIcon: some View {
        Image(systemName: "person.3")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.primary)
            .frame(width: 40, height: 28)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    private var noPlanRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
            Text(noPlanText)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func statColumn(title: String, value: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(value == noResultText ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // Dots read at a glance for small groups; bigger ones keep the number only.
    @ViewBuilder
    private func resultDots(_ plan: TeamGroupPlanSummary) -> some View {
        if let total = group.memberCount, total <= 8 {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < plan.entryCount ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 2)
        } else {
            Text(" ")
                .font(.caption)
        }
    }

    // MARK: - Derived

    private var todayPlan: TeamGroupPlanSummary? {
        group.lastPlan.flatMap { $0.day == today ? $0 : nil }
    }

    private var subtitle: String {
        let parts = [isMine ? yourGroupText : nil, group.memberCount.map(membersText)].compactMap { $0 }
        return parts.isEmpty ? String(localized: "Group") : parts.joined(separator: " · ")
    }

    private var myResultText: String {
        guard let points = myEntry?.effortPoints else { return noResultText }
        return String(localized: "\(points) pts")
    }

    private var myResultCaption: String {
        guard let entry = myEntry else { return " " }
        return entry.isLate ? String(localized: "late") : String(localized: "sent")
    }

    private func resultsText(_ plan: TeamGroupPlanSummary) -> String {
        guard let total = group.memberCount else { return "\(plan.entryCount)" }
        return String(localized: "\(plan.entryCount) of \(total)")
    }

    private func minutesText(_ minutes: Int) -> String {
        String(localized: "\(minutes) min")
    }

    private func membersText(_ count: Int) -> String {
        String(localized: "\(count) members")
    }

    // MARK: - Text

    private let yourGroupText = String(localized: "Your group")
    private let planTitle = String(localized: "Plan today")
    private let resultsTitle = String(localized: "Results")
    private let yourResultTitle = String(localized: "Your result")
    private let noResultText = "—"
    private let noPlanText = String(localized: "No plan today")
}
