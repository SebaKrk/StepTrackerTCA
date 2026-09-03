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
                state.alert = AlertState {
                    TextState("Couldn't Delete Entry")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("OK")
                    }
                } message: {
                    TextState("The entry was not deleted. Please try again.")
                }
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

// MARK: - Confirmation Dialog State

extension ConfirmationDialogState where Action == PRMovementDetailFeature.Action.Dialog {

    /// Destructive confirmation titled with the entry's score and date (FR-006).
    static func deleteEntry(_ entry: PREntry) -> ConfirmationDialogState {
        ConfirmationDialogState(titleVisibility: .visible) {
            TextState(
                String(
                    localized: "Delete \(PRScoreFormatter.string(for: entry.score)) from \(entry.date.formatted(date: .abbreviated, time: .omitted))?"
                )
            )
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(entry.id)) {
                TextState(String(localized: "Delete entry"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        }
    }
}
