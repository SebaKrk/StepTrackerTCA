//
//  ClassDetailFeature+AlertState.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import ComposableArchitecture
import Foundation

/// Alert states for `ClassDetailFeature`.
extension AlertState where Action == ClassDetailFeature.Action.Alert {

    /// Cascade delete confirmation — kopia z `ClassesListFeature` (ten sam UX message,
    /// inny Action type). Trener musi explicit potwierdzić, bo cascade kasuje też
    /// past sessions + athlete HR records.
    static func deleteClass(_ className: String) -> Self {
        Self {
            TextState(String(localized: "Delete class?", bundle: .main))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete) {
                TextState(String(localized: "Delete", bundle: .main))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel", bundle: .main))
            }
        } message: {
            TextState(String(localized: "This will also delete all related sessions and athlete data.", bundle: .main))
        }
    }
}
