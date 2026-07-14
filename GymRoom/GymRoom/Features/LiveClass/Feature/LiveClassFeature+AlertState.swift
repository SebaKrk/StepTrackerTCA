//
//  LiveClassFeature+AlertState.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

/// Alert states for `LiveClassFeature`.
extension AlertState where Action == LiveClassFeature.Action.Alert {

    /// Confirmation dialog before ending the class — prevents accidental tap
    /// that would disconnect all athletes mid-session. Destructive style on End
    /// button + cancel role on Cancel button (Apple system styling: red destructive,
    /// bold cancel).
    static let endClass = Self {
        TextState(String(localized: "End class?", bundle: .main))
    } actions: {
        ButtonState(role: .destructive, action: .confirmEnd) {
            TextState(String(localized: "End", bundle: .main))
        }
        ButtonState(role: .cancel) {
            TextState(String(localized: "Cancel", bundle: .main))
        }
    } message: {
        TextState(String(localized: "All athletes will be disconnected.", bundle: .main))
    }
}
