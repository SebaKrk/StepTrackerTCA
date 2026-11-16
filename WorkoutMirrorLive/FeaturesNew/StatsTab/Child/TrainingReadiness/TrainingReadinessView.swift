//
//  TrainingReadinessView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//
import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TrainingReadinessFeature.self)
struct TrainingReadinessView: View {
    
    @Bindable var store: StoreOf<TrainingReadinessFeature>
    
    var body: some View {
        GroupBox {
            cardContent
        } label: {
            header
        }
        .styledGroupBox()
        .frame(height: cardHeight)
        .onAppear {
            send(.viewDidAppear)
        }
        .skeleton(isLoading: store.contentState == .loading)
        .subscriptionOverlay(
             contentState: store.contentState,
             subscriptionTier: store.subscriptionTier,
             requiredTier: store.requiredTier,
             onUnlockTapped: {
                 // send(.unlockButtonTapped)
             },
             onHealthAccessTapped: {
                 // send(.requestHealthAccessTapped)
             },
             onRetryTapped: {
                 send(.retryButtonTapped)
             })
        .sheet(
            item: $store.scope(
                state: \.destination?.explanation,
                action: \.destination.explanation
            )
        ) { explanationStore in
            ReadinessExplanationView(store: explanationStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    /// Either the waiting explanation or the score itself.
    @ViewBuilder
    private var cardContent: some View {
        if store.isAwaitingSleepData {
            awaitingSleepData
        } else {
            charts
        }
    }

    /// Card title, the level it currently shows, and the way into the explanation.
    private var header: some View {
        HStack(spacing: 8) {
            titleLabel

            Spacer(minLength: 8)

            readinessLevelLabel

            infoButton
        }
    }

    /// Card name; never truncated — the level label shrinks instead.
    private var titleLabel: some View {
        Text("Training Readiness", bundle: .main)
            .font(.caption)
            .fixedSize()
    }

    /// Opens the explanation of what the number is and is not.
    ///
    /// The score carries no context on the card — a bare 55 says nothing about
    /// where it came from or what it leaves out, and this is the only place to
    /// say that the figures are indicative.
    private var infoButton: some View {
        Button {
            send(.infoButtonTapped)
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("About Training Readiness", bundle: .main))
    }

    /// The level name, hidden rather than removed so the info button never jumps.
    ///
    /// Shrinks instead of wrapping: the card is a fixed height and the heading has
    /// to hold the title, this label and the button on the narrowest iPhone.
    private var readinessLevelLabel: some View {
        Text(readinessLevelText)
            .font(.caption)
            .foregroundStyle(store.readinessTint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .opacity(store.isReadinessLevelVisible ? 1 : 0)
            .accessibilityHidden(!store.isReadinessLevelVisible)
    }

    /// Level name, qualified when the score rests on partial data.
    ///
    /// Said in the same line rather than a second row: the card is a fixed height
    /// and another row would push the chart out of it.
    private var readinessLevelText: String {
        guard store.isResultProvisional else { return store.readinessLabel }

        return "\(store.readinessLabel) · \(String(localized: "estimated", bundle: .main))"
    }

    /// Shown before the night closes, in place of a score that cannot exist yet.
    ///
    /// Laid out by hand rather than with `ContentUnavailableView`, whose padding
    /// does not fit the fixed card height.
    private var awaitingSleepData: some View {
        VStack(spacing: 6) {
            Image(systemName: "bed.double")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Waiting for sleep data", bundle: .main)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(awaitingSleepHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .transition(.opacity)
    }

    /// Tells the user when the score should appear, when that is known.
    private var awaitingSleepHint: String {
        guard let expectedBy = store.sleepDataExpectedBy else {
            return String(localized: "Your score appears once the night is recorded", bundle: .main)
        }

        let time = expectedBy.formatted(date: .omitted, time: .shortened)

        return String(localized: "Your score appears after \(time)", bundle: .main)
    }

    /// Fixed so the card lines up with its neighbours in the stats grid.
    ///
    /// Scaled, because everything inside it — heading, level label, axis labels
    /// and the value pill — grows with Dynamic Type while a hard 120 would not.
    @ScaledMetric(relativeTo: .caption) private var cardHeight: CGFloat = 120

    @ViewBuilder
    private var charts: some View {
        Chart {
            readinessChart()
            readinessIndicator(store.readinessValue)
                .annotation(position: .top, alignment: .center, spacing: -10) {
                    readinessLabel(
                        value: store.readinessValue,
                        color: store.readinessTint
                    )
                }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis {
            // `fixedSize` is required — without it Charts compresses every label
            // to an ellipsis. `anchor: .top` is what centres it on its own value.
            AxisMarks(values: ReadinessLevel.axisValues) { value in
                AxisValueLabel(anchor: .top) {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.footnote)
                            .fixedSize()
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.frame(height: 10)
        }
        .frame(height: 60)
    }
    
}
