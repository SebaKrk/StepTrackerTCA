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

    /// Card title and, once there is a score, its level.
    private var header: some View {
        HStack {
            Text("Training Readiness", bundle: .main)
                .font(.caption)

            Spacer()

            readinessLevelLabel
        }
    }

    /// The level name, hidden rather than removed so the header does not reflow.
    private var readinessLevelLabel: some View {
        Text(store.readinessLabel)
            .font(.caption)
            .foregroundStyle(store.readinessLevel.color)
            .opacity(store.isReadinessLevelVisible ? 1 : 0)
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
