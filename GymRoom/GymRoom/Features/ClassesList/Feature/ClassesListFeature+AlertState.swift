//
//  ClassesListFeature+AlertState.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import ComposableArchitecture
import Foundation

/// Alert states for `ClassesListFeature`.
extension AlertState where Action == ClassesListFeature.Action.Alert {

    /// Confirmation dialog before destructive cascade delete — usunięcie template'a
    /// kasuje też wszystkie past session records + athlete records (HR samples,
    /// analytics). Bez tej confirmation jeden tap by mógł wymazać godziny treningów.
    ///
    /// `className` wstrzykiwany dla personalizacji message (".. delete 'Crossfit'?")
    /// — user widzi konkretnie którą klasę usuwa, mniejsza szansa pomyłki.
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
