//
//  GymRoomRootView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import SwiftUI

/// Root view GymRoom iPad app. NavigationSplitView z 2 sekcjami w sidebar:
/// **Classes** (main hub: ClassesListView) + **History** (placeholder, subtask D).
///
/// LiveClass fullScreenCover sterowany przez `ClassesListFeature` child — overlay
/// overrides całą NavigationSplitView (sidebar + detail), trener widzi tylko tile grid.
@ViewAction(for: GymRoomRootFeature.self)
struct GymRoomRootView: View {

    @Bindable var store: StoreOf<GymRoomRootFeature>

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Private views (struktura)

    private var sidebar: some View {
        List(
            GymRoomRootFeature.SidebarItem.allCases,
            selection: Binding(
                get: { store.selectedItem },
                set: { newValue in
                    guard let newValue else { return }
                    send(.sidebarItemSelected(newValue))
                }
            )
        ) { item in
            sidebarRow(for: item)
        }
        .navigationTitle(sidebarTitle)
    }

    private func sidebarRow(for item: GymRoomRootFeature.SidebarItem) -> some View {
        Label {
            Text(item.title)
        } icon: {
            Image(systemName: item.symbol)
        }
        .tag(item)
    }

    @ViewBuilder
    private var detail: some View {
        switch store.selectedItem {
        case .classes:
            ClassesListView(
                store: store.scope(state: \.classesList, action: \.classesList)
            )
        case .history:
            ClassHistoryView(
                store: store.scope(state: \.history, action: \.history)
            )
        }
    }

    // MARK: - Private content (implementacja)

    private var sidebarTitle: String {
        String(localized: "Gym Room", bundle: .main)
    }
}
