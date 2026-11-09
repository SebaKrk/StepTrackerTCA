//
//  ReadinessExplanationView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ReadinessExplanationFeature.self)
struct ReadinessExplanationView: View {

    let store: StoreOf<ReadinessExplanationFeature>

    var body: some View {
        NavigationStack {
            Form {
                whatItIsSection
                componentsSection
                scaleSection
                baselineSection
                limitsSection
            }
            .navigationTitle(Text("Training Readiness", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    closeButton
                }
            }
        }
    }

    // MARK: - Sections

    /// Opens with the one sentence that answers "what am I looking at".
    private var whatItIsSection: some View {
        Section {
            Text(
                "A single number from 0 to 100 saying how much your body can take today. It compares you against yourself, not against anyone else.",
                bundle: .main
            )
        }
    }

    /// The four signals, each with the question it answers.
    private var componentsSection: some View {
        Section {
            componentRow(
                title: Text("Resting heart rate", bundle: .main),
                detail: Text("Whether your heart has returned to rest.", bundle: .main)
            )

            componentRow(
                title: Text("Heart rate variability", bundle: .main),
                detail: Text("Whether your nervous system is rested.", bundle: .main)
            )

            componentRow(
                title: Text("Sleep", bundle: .main),
                detail: Text("Whether the night was long enough, and how it compares with your own average.", bundle: .main)
            )

            componentRow(
                title: Text("Yesterday's load", bundle: .main),
                detail: Text("How much yesterday's training left for today.", bundle: .main)
            )
        } header: {
            Text("What it is built from", bundle: .main)
        }
    }

    /// Says what 50 means, because a mid-scale number reads as a warning otherwise.
    private var scaleSection: some View {
        Section {
            Text(
                "50 means every signal sits at your usual level. That is normal, not a warning. Above 50 you are better recovered than usual, below it — less.",
                bundle: .main
            )
        } header: {
            Text("What the number means", bundle: .main)
        }
    }

    /// Explains why a gap in wearing the Watch does not break the comparison.
    private var baselineSection: some View {
        Section {
            Text(
                "Every signal is compared against 7 days that have data, looked for across the last 49. A week without the Watch makes the app reach further back instead of averaging fewer days.",
                bundle: .main
            )
        } header: {
            Text("Where your baseline comes from", bundle: .main)
        }
    }

    /// The honest part: what the score cannot know.
    private var limitsSection: some View {
        Section {
            Text(
                "These figures are indicative. They are not a diagnosis and not medical advice.",
                bundle: .main
            )

            Text(
                "The score knows nothing about stress, alcohol, medication or crossing time zones — only about their traces in the signals. If it says you are ready and you feel broken, trust yourself.",
                bundle: .main
            )
        } header: {
            Text("What it does not know", bundle: .main)
        }
    }

    // MARK: - Components

    /// One signal: its name, and the question it answers.
    private func componentRow(title: Text, detail: Text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            title
                .font(.subheadline)

            detail
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var closeButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Text("Done", bundle: .main)
        }
    }
}

#Preview {
    ReadinessExplanationView(
        store: Store(initialState: ReadinessExplanationFeature.State()) {
            ReadinessExplanationFeature()
        }
    )
}
