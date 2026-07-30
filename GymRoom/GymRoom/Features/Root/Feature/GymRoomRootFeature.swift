//
//  GymRoomRootFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

/// Root reducer GymRoom iPad app. NavigationSplitView parent z dwiema sekcjami w sidebar:
/// **Classes** (lista wszystkich klas z + button) i **History** (placeholder — subtask D
/// dostarczy filtered list of past classes z charts/details).
///
/// Child `ClassesListFeature` orchestruje lista + creation + detail push + LiveClass
/// fullScreenCover (overlay overrides sidebar). Root tylko switching detail content.
@Reducer
struct GymRoomRootFeature {

    var body: some Reducer<State, Action> {
        Scope(state: \.classesList, action: \.classesList) {
            ClassesListFeature()
        }
        Scope(state: \.history, action: \.history) {
            ClassHistoryFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {

            case let .view(.sidebarItemSelected(item)):
                state.selectedItem = item
                return .none

            case .classesList, .history, .view:
                return .none
            }
        }
    }
}
