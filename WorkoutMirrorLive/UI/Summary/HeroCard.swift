//
//  HeroCard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SharedModels
import SwiftUI

/// Mockup R2 — Summary hero: activity icon on an accent tint, workout name with
/// "weekday · start – end" meta, dominant-zone pill top-right and the big
/// exercise duration. Store-agnostic: the caller formats all strings.
struct HeroCard: View {

    // MARK: - Properties

    let iconSystemName: String
    let name: String
    let meta: String
    let durationText: String
    let dominantZone: HeartRateZone?
    let accent: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            heroTop
            heroTime
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryCard()
    }

    // MARK: - Structure

    private var heroTop: some View {
        HStack(alignment: .center, spacing: 12) {
            heroIcon
            VStack(alignment: .leading, spacing: 2) {
                heroName
                heroMeta
            }
            Spacer(minLength: 8)
            zonePill
        }
    }

    private var heroTime: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            durationValue
            durationUnit
        }
    }

    // MARK: - Implementation

    private var heroIcon: some View {
        Image(systemName: iconSystemName)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(accent)
            .frame(width: 44, height: 44)
            .background(accent.opacity(0.14), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            )
    }

    private var heroName: some View {
        Text(name)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(SummaryTheme.ink)
    }

    private var heroMeta: some View {
        Text(meta)
            .font(.system(size: 13))
            .foregroundStyle(SummaryTheme.inkSecondary)
    }

    @ViewBuilder
    private var zonePill: some View {
        if let zone = dominantZone {
            HStack(spacing: 6) {
                Circle()
                    .fill(zone.color)
                    .frame(width: 7, height: 7)
                Text(zone.title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(zone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(zone.color.opacity(0.12), in: .capsule)
            .overlay(
                Capsule()
                    .stroke(zone.color.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private var durationValue: some View {
        Text(durationText)
            .font(.system(size: 44, weight: .heavy))
            .monospacedDigit()
            .foregroundStyle(SummaryTheme.ink)
    }

    private var durationUnit: some View {
        Text(String(localized: "exercise time", bundle: .main))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(SummaryTheme.inkSecondary)
    }
}

// MARK: - Previews

#Preview("HeroCard — Strefa 2 (makieta)") {
    VStack(spacing: 12) {
        HeroCard(
            iconSystemName: "dumbbell.fill",
            name: "Trening crossowy",
            meta: "środa · 19:31 – 20:34",
            durationText: "63:30",
            dominantZone: .fatBurning,
            accent: HeartRateZone.fatBurning.color
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}

#Preview("HeroCard — bez stref (mięta) i strefa 5") {
    VStack(spacing: 12) {
        HeroCard(
            iconSystemName: "figure.run",
            name: "Bieganie",
            meta: "piątek · 07:02 – 07:48",
            durationText: "46:12",
            dominantZone: nil,
            accent: SummaryTheme.mint
        )
        HeroCard(
            iconSystemName: "dumbbell.fill",
            name: "Trening crossowy",
            meta: "sobota · 10:00 – 10:41",
            durationText: "41:05",
            dominantZone: .anaerobic,
            accent: HeartRateZone.anaerobic.color
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
