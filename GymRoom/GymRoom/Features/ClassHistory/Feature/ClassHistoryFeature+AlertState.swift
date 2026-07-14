//
//  ClassHistoryFeature+AlertState.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import ComposableArchitecture
import Foundation

/// Alert states for `ClassHistoryFeature`.
extension AlertState where Action == ClassHistoryFeature.Action.Alert {

    /// Cascade delete pojedynczej sesji z History — różny od `deleteClass` (template):
    /// tu kasujemy **jeden historical entry** + athletes z tej sesji. Template zostaje
    /// w grafiku, inne sesje template'a niezmienione. UX: trener czyści śmieci z history
    /// (np. test sessions, anulowane treningi).
    static func deleteSession(_ className: String) -> Self {
        Self {
            TextState(String(localized: "Delete session?", bundle: .main))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete) {
                TextState(String(localized: "Delete", bundle: .main))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel", bundle: .main))
            }
        } message: {
            TextState(String(localized: "This will also delete all athlete data from this class.", bundle: .main))
        }
    }

    /// Force-end ongoing session z History — workaround dla pre-existing bug C
    /// (WC end-flow gdy Watch unreachable). Trener może wymusić `endedAt = .now`
    /// na sesji która `endedAt == nil`. Sets analytics dla athletes z leftAt nil.
    static func endSession(_ className: String) -> Self {
        Self {
            TextState(String(localized: "End session?", bundle: .main))
        } actions: {
            ButtonState(action: .confirmEnd) {
                TextState(String(localized: "End", bundle: .main))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel", bundle: .main))
            }
        } message: {
            TextState(String(localized: "End time will be set to now. Athletes still active will be finalized.", bundle: .main))
        }
    }
}
