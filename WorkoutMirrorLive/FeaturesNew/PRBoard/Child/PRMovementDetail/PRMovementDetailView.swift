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
    }

    // MARK: - Structure

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                categoryBadge
                if store.movement.rxStandard != nil {
                    rxStandardCard
                }
                emptyState
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
