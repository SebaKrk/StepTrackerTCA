//
//  ReadinessExplanationView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ReadinessExplanationFeature.self)
struct ReadinessExplanationView: View {

    /// The store backing this screen.
    let store: StoreOf<ReadinessExplanationFeature>

    var body: some View {
        NavigationStack {
            rootView
                .navigationTitle(Text("Training Readiness", bundle: .main))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        closeButton
                    }
                }
        }
    }

    // MARK: - Cards

    /// Cards on a tinted wash, the same shell the metric details screen uses.
    private var rootView: some View {
        ScrollView {
            VStack(spacing: 2) {
                whatItIsCard
                componentsCard
                scaleCard
                baselineCard
                limitsCard
            }
            .padding()
        }
        .background(backgroundWash.ignoresSafeArea())
    }

    /// Opens with the one sentence that answers "what am I looking at".
    private var whatItIsCard: some View {
        explanationCard(
            icon: "figure.run",
            title: Text("What this is", bundle: .main)
        ) {
            prose(
                Text(
                    "A single number from 0 to 100 saying how much your body can take today. It compares you against yourself, not against anyone else.",
                    bundle: .main
                )
            )
        }
    }

    /// The four signals, each with the question it answers.
    private var componentsCard: some View {
        explanationCard(
            icon: "square.grid.2x2",
            title: Text("What it is built from", bundle: .main)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                componentRow(
                    metric: .rhr,
                    title: Text("Resting heart rate", bundle: .main),
                    detail: Text("Whether your heart has returned to rest.", bundle: .main)
                )

                componentRow(
                    metric: .hrv,
                    title: Text("Heart rate variability", bundle: .main),
                    detail: Text("Whether your nervous system is rested.", bundle: .main)
                )

                componentRow(
                    metric: .sleep,
                    title: Text("Sleep", bundle: .main),
                    detail: Text("How the night compares with your own average.", bundle: .main)
                )

                componentRow(
                    metric: .activity,
                    title: Text("Yesterday's load", bundle: .main),
                    detail: Text("How much yesterday's training left for today.", bundle: .main)
                )
            }
        }
    }

    /// Says what 50 means, because a mid-scale number reads as a warning otherwise.
    private var scaleCard: some View {
        explanationCard(
            icon: "gauge.with.dots.needle.33percent",
            title: Text("What the number means", bundle: .main)
        ) {
            prose(
                Text(
                    "50 means every signal sits at your usual level. That is normal, not a warning. Above 50 you are better recovered than usual, below it — less.",
                    bundle: .main
                )
            )
        }
    }

    /// Explains why a gap in wearing the Watch does not break the comparison.
    private var baselineCard: some View {
        explanationCard(
            icon: "calendar",
            title: Text("Where your baseline comes from", bundle: .main)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                prose(
                    Text(
                        "Every signal is compared against 7 days that have data, looked for across the last 49. A week without the Watch makes the app reach further back instead of averaging fewer days.",
                        bundle: .main
                    )
                )

                prose(
                    Text(
                        "That is separate from history: on first launch the app rebuilds 60 days of results from Apple Health, so the trend chart means something straight away.",
                        bundle: .main
                    )
                )
            }
        }
    }

    /// The honest part: what the score cannot know.
    private var limitsCard: some View {
        explanationCard(
            icon: "exclamationmark.triangle.fill",
            title: Text("What it does not know", bundle: .main),
            tint: .orange
        ) {
            VStack(alignment: .leading, spacing: 12) {
                prose(
                    Text(
                        "These figures are indicative. They are not a diagnosis and not medical advice.",
                        bundle: .main
                    )
                )

                prose(
                    Text(
                        "The score knows nothing about stress, alcohol, medication or crossing time zones — only about their traces in the signals. If it says you are ready and you feel broken, trust yourself.",
                        bundle: .main
                    )
                )
            }
        }
    }

    // MARK: - Components

    /// One titled card of prose, in the metric details skin.
    ///
    /// `tint` colours the heading only — used by the limits card, which is the one
    /// section that is a caveat rather than a description.
    ///
    /// Headings carry full contrast rather than the muted grey the metric cards
    /// use: here they are the only way through a screen of prose, so they have to
    /// be scannable on their own.
    private func explanationCard<Content: View>(
        icon: String,
        title: Text,
        tint: Color = .primary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon)

                    title

                    Spacer()
                }
                .foregroundStyle(tint)
                .font(.subheadline)
                .fontWeight(.semibold)

                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }

    /// One signal: its icon, its name, and the question it answers.
    ///
    /// The icon is the metric's own, so a row here is recognisable as the tile it
    /// describes rather than as a separate list of words.
    private func componentRow(metric: HealthMetricType, title: Text, detail: Text) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: metric.icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                detail
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Body copy, at the weight the app uses for descriptions.
    private func prose(_ text: Text) -> some View {
        text
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Dismisses the sheet.
    private var closeButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Image(systemName: "checkmark")
        }
        .accessibilityLabel(Text("Done", bundle: .main))
    }

    /// Diagonal wash in the level's colour, tying the sheet to the card it came from.
    ///
    /// Applied ignoring the safe area, so it runs under the navigation bar — with
    /// the wash stopping at the safe area the bar stayed black and cut a hard line
    /// across the top of the screen.
    private var backgroundWash: some View {
        LinearGradient(
            colors: [store.level.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

}

#Preview {
    ReadinessExplanationView(
        store: Store(initialState: ReadinessExplanationFeature.State(level: .fair)) {
            ReadinessExplanationFeature()
        }
    )
}
