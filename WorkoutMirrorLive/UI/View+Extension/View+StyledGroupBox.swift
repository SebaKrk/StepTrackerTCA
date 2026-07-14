//
//  View+StyledGroupBox.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI

extension View {
    func styledGroupBox() -> some View {
        self.modifier(StyledGroupBoxModifier())
    }
}
