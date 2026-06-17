//
//  ClassHistoryPlaceholderView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import SwiftUI

/// Placeholder dla History tab — subtask D dostarczy filtered list past klas z charts
/// + summary stats. Aktualnie tylko ContentUnavailableView z "Coming soon".
struct ClassHistoryPlaceholderView: View {

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "clock.arrow.circlepath")
        } description: {
            Text(description)
        }
        .navigationTitle(title)
    }

    // MARK: - Private content (implementacja)

    private var title: String {
        String(localized: "History", bundle: .main)
    }

    private var description: String {
        String(localized: "Past classes will appear here soon.", bundle: .main)
    }
}

#Preview {
    NavigationStack {
        ClassHistoryPlaceholderView()
    }
}
