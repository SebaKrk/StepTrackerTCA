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
    }

    // MARK: - Structure

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                categoryCards
            }
            .padding(.horizontal)
        }
    }

    private var categoryCards: some View {
        ForEach(PRCategory.allCases) { category in
            categoryCard(for: category)
        }
    }

    // MARK: - Implementation

    private func categoryCard(for category: PRCategory) -> some View {
        Button {
            send(.categoryTapped(category))
        } label: {
            GroupBox {
                categoryCardContent(for: category)
            } label: {
                categoryCardHeader(for: category)
            }
            .styledGroupBox()
        }
        .buttonStyle(.plain)
    }

    private func categoryCardHeader(for category: PRCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
        }
    }

    private func categoryCardContent(for category: PRCategory) -> some View {
        HStack {
            recordsCounter(for: category)
            Spacer()
            lastRecordPlaceholder
            chevron
        }
        .padding(.top, 4)
    }

    private func recordsCounter(for category: PRCategory) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("0/\(PRCatalog.movements(in: category).count)")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text(String(localized: "records"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var lastRecordPlaceholder: some View {
        Text("—")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
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
