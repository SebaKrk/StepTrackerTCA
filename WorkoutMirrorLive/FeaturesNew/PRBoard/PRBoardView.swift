//
//  PRBoardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PRBoardFeature.self)
struct PRBoardView: View {
    @Bindable var store: StoreOf<PRBoardFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(String(localized: "PR Board"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { closeToolbarItem }
                .navigationDestination(
                    item: $store.scope(state: \.movementList, action: \.movementList)
                ) { listStore in
                    PRMovementListView(store: listStore)
                }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Structure

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                boardHeroCard
                categoryCards
            }
            .padding(.horizontal)
        }
        .background(PRBoardPalette.screenBackground(glow: PRBoardPalette.mint))
    }

    private var boardHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            heroHeader
            heroCounter
            categoryShareBand
            latestPRRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(heroCardBackground)
    }

    private var categoryCards: some View {
        ForEach(PRCategory.allCases) { category in
            categoryCard(for: category)
        }
    }

    private func categoryCard(for category: PRCategory) -> some View {
        Button {
            send(.categoryTapped(category))
        } label: {
            VStack(spacing: 12) {
                categoryCardTop(for: category)
                categoryProgressBar(for: category)
            }
            .padding(14)
            .prCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Implementation (hero)

    private var heroHeader: some View {
        HStack(spacing: 12) {
            heroIcon
            VStack(alignment: .leading, spacing: 2) {
                Text("Your records")
                    .font(.headline)
                Text("\(PRCatalog.movements.count) movements in \(PRCategory.allCases.count) categories")
                    .font(.footnote)
                    .foregroundStyle(PRBoardPalette.inkSecondary)
            }
        }
    }

    private var heroIcon: some View {
        Image(systemName: "trophy.fill")
            .font(.title3)
            .foregroundStyle(PRBoardPalette.gold)
            .frame(width: 44, height: 44)
            .background(PRBoardPalette.gold.opacity(0.13), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PRBoardPalette.gold.opacity(0.28), lineWidth: 1)
            )
    }

    private var heroCounter: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            heroCounterNumber
            Text("movements with a record")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PRBoardPalette.inkSecondary)
        }
    }

    private var heroCounterNumber: some View {
        Text("\(store.completedCount)")
            .font(.system(size: 44, weight: .heavy))
            .foregroundStyle(PRBoardPalette.ink)
        + Text("/\(PRCatalog.movements.count)")
            .font(.title2.bold())
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    private var categoryShareBand: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(PRCategory.allCases) { category in
                    categoryShareSegment(for: category, totalWidth: proxy.size.width)
                }
                RoundedRectangle(cornerRadius: 2)
                    .fill(PRBoardPalette.trackFill)
            }
        }
        .frame(height: 10)
        .clipShape(.rect(cornerRadius: 5))
        .accessibilityLabel(Text("Category share of records"))
    }

    @ViewBuilder
    private func categoryShareSegment(for category: PRCategory, totalWidth: CGFloat) -> some View {
        let count = store.completedCountByCategory[category, default: 0]
        if count > 0 {
            RoundedRectangle(cornerRadius: 2)
                .fill(category.color)
                .frame(width: totalWidth * CGFloat(count) / CGFloat(PRCatalog.movements.count))
        }
    }

    @ViewBuilder
    private var latestPRRow: some View {
        if let entry = store.latestEntry,
           let movement = PRCatalog.movement(id: entry.movementId) {
            HStack(spacing: 10) {
                prChip
                latestPRText(movement: movement, entry: entry)
                Spacer(minLength: 8)
                latestPRDate(entry.date)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(latestPRBackground)
        }
    }

    private var prChip: some View {
        Text(verbatim: "PR")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(PRBoardPalette.goldInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(PRBoardPalette.gold, in: .rect(cornerRadius: 6))
    }

    private func latestPRText(movement: PRMovement, entry: PREntry) -> some View {
        (
            Text(movement.name)
                .fontWeight(.bold)
                .foregroundStyle(PRBoardPalette.ink)
            + Text(verbatim: " · \(PRScoreFormatter.string(for: entry.score))")
                .foregroundStyle(PRBoardPalette.inkSecondary)
        )
        .font(.footnote)
        .lineLimit(1)
    }

    private func latestPRDate(_ date: Date) -> some View {
        Text(date, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    // MARK: - Implementation (category cards)

    private func categoryCardTop(for category: PRCategory) -> some View {
        HStack(spacing: 12) {
            categoryIcon(for: category)
            VStack(alignment: .leading, spacing: 1) {
                Text(category.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PRBoardPalette.ink)
                lastRecordLabel(for: category)
            }
            Spacer(minLength: 8)
            categoryCounter(for: category)
            chevron
        }
    }

    private func categoryIcon(for category: PRCategory) -> some View {
        Image(systemName: category.sfSymbolName)
            .font(.body.weight(.semibold))
            .foregroundStyle(category.color)
            .frame(width: 40, height: 40)
            .background(category.color.opacity(0.14), in: .rect(cornerRadius: 13))
    }

    @ViewBuilder
    private func lastRecordLabel(for category: PRCategory) -> some View {
        if let date = store.latestDateByCategory[category] {
            Text("last PR: \(date, format: .relative(presentation: .named))")
                .font(.caption)
                .foregroundStyle(PRBoardPalette.inkTertiary)
        } else {
            Text("no entries yet")
                .font(.caption)
                .foregroundStyle(PRBoardPalette.inkTertiary)
        }
    }

    private func categoryCounter(for category: PRCategory) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            categoryCounterNumber(for: category)
            Text("records")
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(PRBoardPalette.inkTertiary)
        }
    }

    private func categoryCounterNumber(for category: PRCategory) -> some View {
        Text("\(store.completedCountByCategory[category, default: 0])")
            .font(.title3.weight(.heavy))
            .foregroundStyle(PRBoardPalette.ink)
        + Text("/\(PRCatalog.movements(in: category).count)")
            .font(.footnote.bold())
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    private func categoryProgressBar(for category: PRCategory) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PRBoardPalette.trackFill)
                Capsule()
                    .fill(category.color)
                    .frame(width: proxy.size.width * completionFraction(for: category))
            }
        }
        .frame(height: 6)
    }

    private func completionFraction(for category: PRCategory) -> CGFloat {
        let total = PRCatalog.movements(in: category).count
        guard total > 0 else { return 0 }
        return CGFloat(store.completedCountByCategory[category, default: 0]) / CGFloat(total)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    // MARK: - Implementation (chrome)

    private var heroCardBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(PRBoardPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [PRBoardPalette.mint.opacity(0.10), .white.opacity(0.02)],
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

    private var latestPRBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(PRBoardPalette.cardElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PRBoardPalette.stroke, lineWidth: 1)
            )
    }

    @ToolbarContentBuilder
    private var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            send(.closeTapped)
        } label: {
            Image(systemName: "xmark")
        }
    }
}

#Preview {
    PRBoardView(
        store: Store(initialState: PRBoardFeature.State()) {
            PRBoardFeature()
        }
    )
}
