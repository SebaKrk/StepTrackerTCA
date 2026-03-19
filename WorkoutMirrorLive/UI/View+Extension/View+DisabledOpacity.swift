//
//  View+DisabledOpacity.swift
//  WorkoutMirrorLive
//

import SwiftUI

extension View {

    /// Disables the view and dims it to `disabledOpacity` when `isDisabled` is `true`.
    func disabledWithOpacity(_ isDisabled: Bool, opacity disabledOpacity: Double = 0.35) -> some View {
        self
            .disabled(isDisabled)
            .opacity(isDisabled ? disabledOpacity : 1)
    }

}
