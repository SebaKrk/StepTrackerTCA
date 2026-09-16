//
//  ResultCardHeader.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Header row of a result card: type chip (orange strength / blue WOD / gray
/// unplanned), optional cap chip (from the plan's `timeCap` field, never parsed
/// from text), optional name + plan subtitle, status control on the right.
struct ResultCardHeader: View {

    enum Kind {
        case strength
        case wod
        case unplanned
    }

    // MARK: - Properties

    let kind: Kind
    let chipText: String
    let name: String?
    let planSub: String?
    let capText: String?
    let status: StatusControl.Mode?
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerRow
            planSubtitle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Structure

    /// Status must never wrap its text — when the single row runs out of width,
    /// the whole control drops to a second line instead.
    private var headerRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                typeChip
                capChip
                nameLabel
                Spacer(minLength: 8)
                statusControl
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    typeChip
                    capChip
                    nameLabel
                    Spacer(minLength: 0)
                }
                statusControl
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Implementation

    private var typeChip: some View {
        Text(chipText)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.4)
            .foregroundStyle(chipColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(chipColor.opacity(0.13), in: .capsule)
            .overlay(Capsule().stroke(chipColor.opacity(0.3), lineWidth: 1))
    }

    @ViewBuilder
    private var capChip: some View {
        if let capText {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                Text(capText)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.inkSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06), in: .capsule)
            .overlay(Capsule().stroke(theme.stroke, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var nameLabel: some View {
        if let name {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var planSubtitle: some View {
        if let planSub {
            Text(planSub)
                .font(.system(size: 12.5))
                .foregroundStyle(theme.inkTertiary)
        }
    }

    @ViewBuilder
    private var statusControl: some View {
        if let status {
            StatusControl(mode: status, accent: accent)
        }
    }

    private var chipColor: Color {
        switch kind {
        case .strength: theme.strengthChip
        case .wod: theme.wodChip
        case .unplanned: Color.gray
        }
    }
}

// MARK: - Previews

#Preview("ResultCardHeader — 3 warianty (galeria 2)") {
    VStack(spacing: 12) {
        VStack {
            ResultCardHeader(
                kind: .strength,
                chipText: "Strength",
                name: "Back Squat",
                planSub: "Plan: 2×2 @ 85%, 3×2 @ 95%",
                capText: nil,
                status: nil,
                accent: SummaryTheme.mint
            )
        }
        .summaryCard()

        VStack {
            ResultCardHeader(
                kind: .wod,
                chipText: "WOD 1",
                name: nil,
                planSub: nil,
                capText: "11 min cap",
                status: .segment(status: .completed, onChange: { _ in }),
                accent: SummaryTheme.mint
            )
        }
        .summaryCard()

        VStack {
            ResultCardHeader(
                kind: .wod,
                chipText: "EMOM 12",
                name: nil,
                planSub: nil,
                capText: nil,
                status: .pill(completed: true),
                accent: SummaryTheme.mint
            )
        }
        .summaryCard()
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
