//
//  PRMovementDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

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
    }

    // MARK: - Structure

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                categoryBadge
                if let best = store.summary.best {
                    currentPRCard(best)
                }
                if store.movement.rxStandard != nil {
                    rxStandardCard
                }
                if store.entries.isEmpty {
                    emptyState
                } else {
                    historyCard
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Implementation

    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.movement.category.color)
                .frame(width: 8, height: 8)
            Text(store.movement.category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var rxStandardCard: some View {
        GroupBox {
            rxStandardText
        } label: {
            rxStandardHeader
        }
        .styledGroupBox()
    }

    private var rxStandardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Rx standard"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
        }
    }

    private var rxStandardText: some View {
        HStack {
            Text(store.movement.rxStandard ?? "")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func currentPRCard(_ best: PREntry) -> some View {
        GroupBox {
            HStack(alignment: .firstTextBaseline) {
                Text(PRScoreFormatter.string(for: best.score))
                    .font(.largeTitle.bold())
                    .foregroundStyle(store.movement.category.color)
                Spacer()
                Text(best.date, format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Current PR"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
            }
        }
        .styledGroupBox()
    }

    private var historyCard: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(store.entries) { entry in
                    historyRow(entry)
                    if entry.id != store.entries.last?.id {
                        Divider()
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "History"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
            }
        }
        .styledGroupBox()
    }

    private func historyRow(_ entry: PREntry) -> some View {
        HStack(spacing: 8) {
            Text(entry.date, format: .dateTime.day().month().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            equipmentIcons(entry.equipment)
            if let rpe = entry.rpe {
                Text("RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(PRScoreFormatter.string(for: entry.score))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            deleteEntryButton(entry)
        }
    }

    private func equipmentIcons(_ equipment: Set<PREquipment>) -> some View {
        HStack(spacing: 4) {
            ForEach(equipment.sorted { $0.rawValue < $1.rawValue }, id: \.self) { item in
                Image(systemName: item.sfSymbolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "No entries yet"), systemImage: "trophy")
        } description: {
            Text(String(localized: "Your personal records for this movement will appear here."))
        } actions: {
            addFirstEntryButton
        }
        .padding(.top, 24)
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
        .tint(store.movement.category.color)
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
