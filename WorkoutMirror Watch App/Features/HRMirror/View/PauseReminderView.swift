//
//  PauseReminderView.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Ściuba on 24/11/2026.
//

import SwiftUI

/// Asks whether a paused workout is still going; Resume is first because it is the likely answer.
struct PauseReminderView: View {

    // MARK: - Properties

    /// Called when the wearer chooses to resume the workout.
    let onResume: () -> Void

    /// Called when the wearer confirms the pause is meant.
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                pauseIcon
                title
                message
                resumeButton
                dismissButton
            }
        }
    }

    // MARK: - Implementation

    /// Decorative pause mark above the question.
    private var pauseIcon: some View {
        Image(systemName: "pause.circle.fill")
            .font(.title3)
            .foregroundStyle(.orange)
            .accessibilityHidden(true)
    }

    /// The question itself.
    private var title: some View {
        Text(String(localized: "Still training?"))
            .font(.headline)
            .multilineTextAlignment(.center)
    }

    /// Says why the Watch is asking.
    private var message: some View {
        Text(String(localized: "The workout is paused, but your heart rate says you are working."))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    /// Primary action: continue the workout.
    private var resumeButton: some View {
        Button {
            onResume()
        } label: {
            Text(String(localized: "Resume"))
                .frame(maxWidth: .infinity)
        }
        .tint(.green)
        .padding(.top, 8)
    }

    /// Secondary action: the pause is meant.
    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            Text(String(localized: "OK"))
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    PauseReminderView(onResume: {}, onDismiss: {})
}
