//
//  PRMovementDetailFeature+ConfirmationDialogState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

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
