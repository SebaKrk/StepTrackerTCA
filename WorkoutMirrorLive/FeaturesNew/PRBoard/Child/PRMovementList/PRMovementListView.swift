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
    }

    private var subgroupCards: some View {
        ForEach(store.sections, id: \.subgroup) { section in
            subgroupCard(section.subgroup, movements: section.movements)
        }
    }

    // MARK: - Implementation

    private func subgroupCard(_ subgroup: PRSubgroup, movements: [PRMovement]) -> some View {
        GroupBox {
            movementRows(movements)
        } label: {
            subgroupHeader(subgroup)
        }
        .styledGroupBox()
    }

    private func subgroupHeader(_ subgroup: PRSubgroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subgroup.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
        }
    }

    private func movementRows(_ movements: [PRMovement]) -> some View {
        VStack(spacing: 0) {
            ForEach(movements) { movement in
                movementRow(movement)
                if movement.id != movements.last?.id {
                    Divider()
                }
            }
        }
    }

    private func movementRow(_ movement: PRMovement) -> some View {
        Button {
            send(.movementTapped(movement))
        } label: {
            movementRowLabel(movement)
        }
        .buttonStyle(.plain)
    }

    private func movementRowLabel(_ movement: PRMovement) -> some View {
        let prLabel = store.prLabelByMovementId[movement.id]
        return HStack {
            // Muted styling only while the movement has no entries; rows stay tappable.
            Text(movement.name)
                .font(.subheadline)
                .foregroundStyle(prLabel == nil ? .secondary : .primary)
            Spacer()
            resultLabel(prLabel)
            chevron
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func resultLabel(_ prLabel: String?) -> some View {
        if let prLabel {
            Text(prLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        } else {
            Text("—")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
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
