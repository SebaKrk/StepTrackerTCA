//
//  ClassHistoryDetailFeature+AlertState.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import ComposableArchitecture
import Foundation

/// Alert states for `ClassHistoryDetailFeature`.
extension AlertState where Action == ClassHistoryDetailFeature.Action.Alert {

    /// Cascade delete sesji z detail view — analogiczny do `ClassHistoryFeature.deleteSession`
    /// (ten sam UX, inny Action type). Trener musi explicit potwierdzić.
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
}
