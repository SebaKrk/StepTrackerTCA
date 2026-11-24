//
//  DatabaseFailureView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import SwiftUI

/// Shown instead of the app when the database could not open at launch.
///
/// One file for the iPhone and the iPad: it is a member of both targets, and each app passes its own message.
struct DatabaseFailureView: View {

    // MARK: - Properties

    /// What the app tells the person to do, in the app's own words.
    let message: String

    /// Technical description of the failure, small, for whoever is asked for help.
    let details: String

    // MARK: - Body (structure)

    var body: some View {
        ScrollView {
            failureMessage
                .containerRelativeFrame(.vertical)
        }
    }

    // MARK: - Content (implementation)

    private var failureMessage: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
            failureDetails
        }
    }

    private var failureDetails: some View {
        Text(details)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(8)
            .textSelection(.enabled)
    }

    // MARK: - Text

    private let title = String(localized: "Your data could not be opened")
}

// MARK: - Preview

#Preview {
    DatabaseFailureView(
        message: "Close the app and open it again.",
        details: "SQLite error 11: database disk image is malformed"
    )
}
