//
//  PRMovementDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PRMovementDetailFeature.self)
struct PRMovementDetailView: View {
    @Bindable var store: StoreOf<PRMovementDetailFeature>

    var body: some View {
        content
            .navigationTitle(store.movement.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { addEntryToolbarItem }
            .sheet(
                item: $store.scope(state: \.editor, action: \.editor)
            ) { editorStore in
                PREntryEditorView(store: editorStore)
            }
            .confirmationDialog(
                $store.scope(state: \.confirmationDialog, action: \.confirmationDialog)
            )
            .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Structure

    private var content: some View {
        Group {
            switch store.layout {
            case .empty:
                emptyScreen
            case .single:
                scrollableScreen(singleEntryLayout)
            case .progressing:
                scrollableScreen(progressingLayout)
            }
        }
        .background(PRBoardPalette.screenBackground(glow: accent))
    }

    /// No scrolling while there is nothing to scroll — the empty state centers
    /// in the free space instead of sticking to the top.
    private var emptyScreen: some View {
        VStack(spacing: 12) {
            rxStandardIfAny
            Spacer()
            emptyState
            Spacer()
        }
        .padding(.horizontal)
    }

    private func scrollableScreen(_ sections: some View) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                sections
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var singleEntryLayout: some View {
        heroIfAny
        rxStandardIfAny
        historyCard
    }

    @ViewBuilder
    private var progressingLayout: some View {
        heroIfAny
        progressCard
        rxStandardIfAny
        historyCard
    }

    // MARK: - Implementation (hero)

    @ViewBuilder
    private var heroIfAny: some View {
        if let best = store.summary.best {
            prHeroCard(best)
        }
    }

    private func prHeroCard(_ best: PREntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heroTopRow(best)
            heroScore(best)
            if let scaled = secondaryScaledBest {
                scaledBestRow(scaled)
            }
            heroFactChips(best)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(heroCardBackground)
    }

    /// Scaled PR shown under the Rx score — only while both slots are filled
    /// (a scaled-only best already IS the hero, decision D2).
    private var secondaryScaledBest: PREntry? {
        guard store.movement.supportsRxScaled, store.summary.bestRx != nil else { return nil }
        return store.summary.bestScaled
    }

    private func heroTopRow(_ best: PREntry) -> some View {
        HStack(spacing: 8) {
            typeChip
            Spacer(minLength: 8)
            if store.movement.supportsRxScaled {
                if best.isRx == true {
                    rxChip
                } else {
                    scaledHeroChip
                }
            }
            prChip
        }
    }

    private var typeChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accent)
                .frame(width: 7, height: 7)
            Text(verbatim: "\(store.movement.category.displayName) · \(store.movement.subgroup.displayName)")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(accent.opacity(0.14), in: .capsule)
        .overlay(Capsule().strokeBorder(accent.opacity(0.3), lineWidth: 1))
    }

    private var rxChip: some View {
        Text(verbatim: "RX")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(PRBoardPalette.mintInk)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(PRBoardPalette.mint, in: .capsule)
    }

    private var scaledHeroChip: some View {
        Text("Scaled")
            .font(.caption2.weight(.heavy))
            .textCase(.uppercase)
            .foregroundStyle(PRBoardPalette.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.06), in: .capsule)
            .overlay(Capsule().strokeBorder(PRBoardPalette.stroke, lineWidth: 1))
    }

    private func scaledBestRow(_ entry: PREntry) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                rxScaledMiniChip(entry)
                Text(PRScoreFormatter.string(for: entry.score))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PRBoardPalette.ink)
                Spacer(minLength: 8)
                Text(entry.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(PRBoardPalette.inkTertiary)
            }
            if let note = entry.scalingNote {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(PRBoardPalette.inkTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(scaledBestBackground)
    }

    private var scaledBestBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(PRBoardPalette.cardElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PRBoardPalette.stroke, lineWidth: 1)
            )
    }

    private var prChip: some View {
        Text(verbatim: "PR")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(PRBoardPalette.goldInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(PRBoardPalette.gold, in: .rect(cornerRadius: 6))
    }

    private func heroScore(_ best: PREntry) -> some View {
        let parts = PRScoreFormatter.parts(for: best.score)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(parts.value)
                .font(.system(size: 48, weight: .heavy))
                .foregroundStyle(accent)
            if let unit = parts.unit {
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PRBoardPalette.inkSecondary)
            }
        }
    }

    private func heroFactChips(_ best: PREntry) -> some View {
        HStack(spacing: 8) {
            factChip(icon: "calendar", text: Text(best.date, format: .dateTime.day().month().year()))
            if let multiple = store.bodyWeightMultiple {
                factChip(
                    icon: "scalemass.fill",
                    text: Text(verbatim: "×\(multiple.formatted(.number.precision(.fractionLength(2)))) BW")
                )
            }
            if let rpe = best.rpe {
                factChip(
                    icon: nil,
                    text: Text(verbatim: "RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))")
                )
            }
        }
    }

    private func factChip(icon: String?, text: Text) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(PRBoardPalette.inkTertiary)
            }
            text
                .font(.caption.weight(.semibold))
                .foregroundStyle(PRBoardPalette.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06), in: .capsule)
        .overlay(Capsule().strokeBorder(PRBoardPalette.stroke, lineWidth: 1))
    }

    // MARK: - Implementation (progress chart)

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "Progress"))
            if store.availableChartYears.count > 1 {
                chartYearChips
            }
            progressChart
        }
        .padding(16)
        .prCard()
    }

    private var chartYearChips: some View {
        HStack(spacing: 6) {
            ForEach(store.availableChartYears, id: \.self) { year in
                chartYearChip(year)
            }
        }
    }

    private func chartYearChip(_ year: Int) -> some View {
        Button {
            send(.chartYearTapped(year))
        } label: {
            chartYearChipLabel(year, isSelected: year == store.effectiveChartYear)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func chartYearChipLabel(_ year: Int, isSelected: Bool) -> some View {
        if isSelected {
            Text(verbatim: "\(year)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PRBoardPalette.base)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(accent, in: .capsule)
        } else {
            Text(verbatim: "\(year)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PRBoardPalette.inkSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06), in: .capsule)
                .overlay(Capsule().strokeBorder(PRBoardPalette.stroke, lineWidth: 1))
        }
    }

    private var progressChart: some View {
        Chart(store.chartPoints) { point in
            if let standard = point.standard {
                // Rx and scaled plot as separate series — a mixed line would
                // fake progress whenever the standard changes between attempts.
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Result", point.value)
                )
                .foregroundStyle(by: .value("Standard", standard))
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Result", point.value)
                )
                .foregroundStyle(by: .value("Standard", standard))
            } else {
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Result", point.value)
                )
                .foregroundStyle(accent)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Result", point.value)
                )
                .foregroundStyle(accent)
            }
        }
        .chartForegroundStyleScale([
            "Rx": accent,
            String(localized: "Scaled"): PRBoardPalette.inkSecondary,
        ])
        .chartYScale(domain: chartYDomain)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let raw = value.as(Double.self) {
                        Text(yAxisLabel(raw))
                    }
                }
            }
        }
        .frame(height: 180)
    }

    /// Time scores plot inverted — a shorter (better) time sits higher.
    private var chartYDomain: [Double] {
        let values = store.chartPoints.map(\.value)
        let low = (values.min() ?? 0) * 0.95
        let high = (values.max() ?? 1) * 1.05
        return store.isTimeScored ? [high, low] : [low, high]
    }

    private func yAxisLabel(_ raw: Double) -> String {
        if store.isTimeScored {
            let seconds = Int(raw)
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
        return raw.formatted(.number.precision(.fractionLength(0...1)))
    }

    // MARK: - Implementation (Rx standard)

    @ViewBuilder
    private var rxStandardIfAny: some View {
        if let standard = store.movement.rxStandard {
            rxStandardCard(standard)
        }
    }

    private func rxStandardCard(_ standard: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "Rx standard"))
            Text(standard)
                .font(.subheadline)
                .foregroundStyle(PRBoardPalette.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .prCard()
    }

    // MARK: - Implementation (history)

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            historyHeader
            historyRows
        }
        .padding(16)
        .prCard()
    }

    private var historyHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            sectionHeader(String(localized: "History"))
            Spacer()
            Text("\(store.entries.count) entries")
                .font(.caption)
                .foregroundStyle(PRBoardPalette.inkTertiary)
        }
    }

    private var historyRows: some View {
        VStack(spacing: 0) {
            ForEach(store.entries) { entry in
                historyRow(entry)
                if entry.id != store.entries.last?.id {
                    hairline
                }
            }
        }
    }

    private func historyRow(_ entry: PREntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            historyRowTop(entry)
            historyRowMeta(entry)
            if let scalingNote = entry.scalingNote {
                historyScalingNote(scalingNote)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            deleteEntryButton(entry)
        }
    }

    private func historyRowTop(_ entry: PREntry) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(entry.date, format: .dateTime.day().month().year())
                .font(.footnote)
                .foregroundStyle(PRBoardPalette.inkSecondary)
            Spacer()
            historyRowValue(entry)
        }
    }

    private func historyRowValue(_ entry: PREntry) -> some View {
        Text(PRScoreFormatter.string(for: entry.score))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(entry.id == store.summary.best?.id ? accent : PRBoardPalette.ink)
    }

    @ViewBuilder
    private func historyRowMeta(_ entry: PREntry) -> some View {
        HStack(spacing: 6) {
            if store.movement.supportsRxScaled {
                rxScaledMiniChip(entry)
            }
            equipmentIcons(entry.equipment)
            if let rpe = entry.rpe {
                miniChip(Text(verbatim: "RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))"))
            }
            if let context = entry.context {
                miniChip(Text(context.displayName))
            }
        }
    }

    @ViewBuilder
    private func rxScaledMiniChip(_ entry: PREntry) -> some View {
        if entry.isRx == true {
            Text(verbatim: "RX")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(PRBoardPalette.mintInk)
                .padding(.horizontal, 7)
                .padding(.vertical, 1)
                .background(PRBoardPalette.mint, in: .rect(cornerRadius: 6))
        } else {
            miniChip(Text("Scaled"))
        }
    }

    private func historyScalingNote(_ note: String) -> some View {
        Text(note)
            .font(.caption2)
            .foregroundStyle(PRBoardPalette.inkTertiary)
            .lineLimit(2)
    }

    private func miniChip(_ text: Text) -> some View {
        text
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(PRBoardPalette.inkSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 1)
            .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(PRBoardPalette.stroke, lineWidth: 1)
            )
    }

    private func equipmentIcons(_ equipment: Set<PREquipment>) -> some View {
        HStack(spacing: 4) {
            ForEach(equipment.sorted { $0.rawValue < $1.rawValue }, id: \.self) { item in
                Image(systemName: item.sfSymbolName)
                    .font(.caption2)
                    .foregroundStyle(PRBoardPalette.inkTertiary)
            }
        }
    }

    // MARK: - Implementation (empty state & actions)

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "No entries yet"), systemImage: "trophy")
        } description: {
            Text(String(localized: "Your personal records for this movement will appear here."))
        } actions: {
            addFirstEntryButton
        }
    }

    @ToolbarContentBuilder
    private var addEntryToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            addEntryButton
        }
    }

    private var addEntryButton: some View {
        Button {
            send(.addEntryTapped)
        } label: {
            Image(systemName: "plus")
        }
    }

    private func deleteEntryButton(_ entry: PREntry) -> some View {
        Button(role: .destructive) {
            send(.deleteEntryTapped(entry))
        } label: {
            Label(String(localized: "Delete entry"), systemImage: "trash")
        }
    }

    private var addFirstEntryButton: some View {
        Button {
            send(.addEntryTapped)
        } label: {
            Text(String(localized: "Add first result"))
        }
        .buttonStyle(.borderedProminent)
        // App-wide AccentColor asset is empty — prominent style melts into dark mode without an explicit tint.
        .tint(accent)
    }

    // MARK: - Implementation (chrome)

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(accent)
    }

    private var heroCardBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(PRBoardPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.10), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(PRBoardPalette.stroke, lineWidth: 1)
            )
    }

    private var hairline: some View {
        Rectangle()
            .fill(PRBoardPalette.hairline)
            .frame(height: 1)
    }

    private var accent: Color {
        store.movement.category.color
    }
}

#Preview {
    NavigationStack {
        PRMovementDetailView(
            store: Store(
                initialState: PRMovementDetailFeature.State(
                    movement: PRCatalog.movement(id: "fran") ?? PRCatalog.movements[0]
                )
            ) {
                PRMovementDetailFeature()
            }
        )
    }
}
