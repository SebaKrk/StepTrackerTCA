//
//  View+SearchToolbar.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/10/2026.
//

import SwiftUI

extension View {
    /// Puts a magnifier that opens into a search field into the navigation bar.
    func searchToolbar(
        title: String,
        phrase: Binding<String>,
        isSearching: Binding<Bool>,
        prompt: String
    ) -> some View {
        modifier(
            SearchToolbarModifier(
                title: title,
                phrase: phrase,
                isSearching: isSearching,
                prompt: prompt
            )
        )
    }
}
