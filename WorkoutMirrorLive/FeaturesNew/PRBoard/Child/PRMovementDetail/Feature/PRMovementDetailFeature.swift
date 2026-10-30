//
//  PRMovementDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct PRMovementDetailFeature {

    // MARK: - Dependency

    @Dependency(\.date.now) var now
    @Dependency(\.prEntryClient) var prEntryClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.addEntryTapped):
                state.editor = PREntryEditorFeature.State(movement: state.movement, now: now)
                return .none

            case let .view(.deleteEntryTapped(entry)):
                state.confirmationDialog = .deleteEntry(entry)
                return .none

            case let .view(.chartYearTapped(year)):
                state.selectedChartYear = year
                return .none

            case let .confirmationDialog(.presented(.confirmDelete(id))):
                // No manual recompute — @FetchAll re-derives the PR from the remaining history.
                return .run { [prEntryClient] send in
                    do {
                        try await prEntryClient.delete(id)
                    } catch {
                        // A failed delete must be distinguishable from success:
                        // surface the alert instead of failing silently.
                        reportIssue(error)
                        await send(.deleteFailed)
                    }
                }

            case .deleteFailed:
                state.alert = .deleteFailed
                return .none

            case .alert:
                return .none

            case .confirmationDialog:
                return .none

            case .editor:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            PREntryEditorFeature()
        }
        .ifLet(\.$confirmationDialog, action: \.confirmationDialog)
        .ifLet(\.$alert, action: \.alert)
    }
}
