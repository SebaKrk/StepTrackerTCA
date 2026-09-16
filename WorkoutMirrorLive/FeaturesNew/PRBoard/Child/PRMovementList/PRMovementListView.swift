//
//  PRMovementListView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PRMovementListFeature.self)
struct PRMovementListView: View {
    @Bindable var store: StoreOf<PRMovementListFeature>

    var body: some View {
        content
            .navigationTitle(store.category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(
                item: $store.scope(state: \.detail, action: \.detail)
            ) { detailStore in
                PRMovementDetailView(store: detailStore)
            }
    }

    // MARK: - Structure

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                subgroupCards
            }
            .padding(.horizontal)
        }
        .background(PRBoardPalette.screenBackground(glow: accent))
    }

    private var subgroupCards: some View {
        ForEach(store.sections, id: \.subgroup) { section in
            subgroupCard(section.subgroup, movements: section.movements)
        }
    }

    private func subgroupCard(_ subgroup: PRSubgroup, movements: [PRMovement]) -> some View {
        VStack(spacing: 4) {
            subgroupHeader(subgroup, movements: movements)
            movementRows(movements)
        }
        .padding(14)
        .prCard()
    }

    // MARK: - Implementation (sections)

    private func subgroupHeader(_ subgroup: PRSubgroup, movements: [PRMovement]) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(subgroup.displayName)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(accent)
            Spacer()
            subgroupCounter(subgroup, total: movements.count)
        }
        .padding(.bottom, 4)
    }

    private func subgroupCounter(_ subgroup: PRSubgroup, total: Int) -> some View {
        Text(verbatim: "\(store.completedCountBySubgroup[subgroup, default: 0])/\(total)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    private func movementRows(_ movements: [PRMovement]) -> some View {
        VStack(spacing: 0) {
            ForEach(movements) { movement in
                movementRow(movement)
                if movement.id != movements.last?.id {
                    hairline
                }
            }
        }
    }

    // MARK: - Implementation (rows)

    private func movementRow(_ movement: PRMovement) -> some View {
        Button {
            send(.movementTapped(movement))
        } label: {
            movementRowLabel(movement)
        }
        .buttonStyle(.plain)
    }

    private func movementRowLabel(_ movement: PRMovement) -> some View {
        HStack(spacing: 10) {
            movementTitles(movement)
            Spacer(minLength: 8)
            scorePill(for: movement)
            chevron
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func movementTitles(_ movement: PRMovement) -> some View {
        // Muted styling only while the movement has no entries; rows stay tappable.
        let hasEntries = store.prLabelByMovementId[movement.id] != nil
        return VStack(alignment: .leading, spacing: 1) {
            Text(movement.name)
                .font(.subheadline.weight(hasEntries ? .semibold : .regular))
                .foregroundStyle(hasEntries ? PRBoardPalette.ink : PRBoardPalette.inkSecondary)
            movementWhenLabel(movement)
        }
    }

    @ViewBuilder
    private func movementWhenLabel(_ movement: PRMovement) -> some View {
        if let date = store.latestDateByMovementId[movement.id] {
            Text(date, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(PRBoardPalette.inkTertiary)
        }
    }

    @ViewBuilder
    private func scorePill(for movement: PRMovement) -> some View {
        if let label = store.prLabelByMovementId[movement.id] {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accent.opacity(0.14), in: .rect(cornerRadius: 9))
        } else {
            Text("enter result")
                .font(.footnote)
                .foregroundStyle(PRBoardPalette.inkTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(emptyPillBorder)
        }
    }

    private var emptyPillBorder: some View {
        RoundedRectangle(cornerRadius: 9)
            .strokeBorder(
                Color.white.opacity(0.14),
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
            )
    }

    private var hairline: some View {
        Rectangle()
            .fill(PRBoardPalette.hairline)
            .frame(height: 1)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(PRBoardPalette.inkTertiary)
    }

    private var accent: Color {
        store.category.color
    }
}

#Preview {
    NavigationStack {
        PRMovementListView(
            store: Store(initialState: PRMovementListFeature.State(category: .benchmarks)) {
                PRMovementListFeature()
            }
        )
    }
}
