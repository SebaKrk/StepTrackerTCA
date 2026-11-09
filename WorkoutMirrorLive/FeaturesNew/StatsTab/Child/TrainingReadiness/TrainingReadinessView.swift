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
        }
    }
    
    /// Either the waiting explanation or the score itself.
    @ViewBuilder
    private var cardContent: some View {
        if store.isAwaitingSleepData {
            awaitingSleepData
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                charts

                readinessLevelLabel
            }
        }
    }

    /// Card title and the way into the explanation.
    private var header: some View {
        HStack {
            Text("Training Readiness", bundle: .main)
                .font(.caption)

            Spacer()

            infoButton
        }
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
        }
        .buttonStyle(.plain)
    }

    /// The level name, hidden rather than removed so the card does not reflow.
    ///
    /// Sits under the chart rather than in the heading, so it is read together
    /// with the value it describes instead of at the far edge of the card.
    private var readinessLevelLabel: some View {
        Text(readinessLevelText)
            .font(.caption)
            .foregroundStyle(
                store.isResultProvisional ? Color.secondary : store.readinessLevel.color
            )
            .opacity(store.isReadinessLevelVisible ? 1 : 0)
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
    private var cardHeight: CGFloat { 120 }

    @ViewBuilder
    private var charts: some View {
        Chart {
            readinessChart()
            readinessIndicator(store.readinessValue)
                .annotation(position: .top, alignment: .center, spacing: -10) {
                    readinessLabel(
                        value: store.readinessValue,
                        color: store.readinessLevel.color
                    )
                }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 25, 50, 75, 90, 100]) { value in
                AxisValueLabel {
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
