//
//  View+StyledGroupBox.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI

extension View {
    /// `tint` colours the whole card instead of the neutral skin — for a card that
    /// is itself a call to action, so the colour does not have to sit on an inner button.
    func styledGroupBox(tint: Color? = nil) -> some View {
        self.modifier(StyledGroupBoxModifier(tint: tint))
    }
}
