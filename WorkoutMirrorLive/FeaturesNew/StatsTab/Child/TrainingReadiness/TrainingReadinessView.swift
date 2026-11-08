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
            if store.isAwaitingSleepData {
                awaitingSleepData
            } else {
                charts
            }
        } label: {
            HStack {
                Text("Training Readiness")
                    .font(.caption)
                Spacer()
                Text(store.readinessLabel)
                    .font(.caption)
                    .foregroundStyle(store.readinessLevel.color)
                    .opacity(isLevelVisible ? 1 : 0)
            }
        }
        .styledGroupBox()
        .frame(height: 120)
        .animation(.snappy(duration: 0.3), value: store.isAwaitingSleepData)
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
    
    /// Shown before the night closes, in place of a score that cannot exist yet.
    ///
    /// Laid out by hand rather than with `ContentUnavailableView`: the card is a
    /// fixed 120pt tall so it lines up with its neighbours, and the system view's
    /// padding does not fit inside that.
    private var awaitingSleepData: some View {
        VStack(spacing: 6) {
            Image(systemName: "bed.double")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Waiting for sleep data")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(awaitingSleepHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .transition(.opacity)
    }

    /// Tells the user when the score should appear, when that is known.
    private var awaitingSleepHint: String {
        guard let expectedBy = store.sleepDataExpectedBy else {
            return String(localized: "Your score appears once the night is recorded")
        }

        let time = expectedBy.formatted(date: .omitted, time: .shortened)

        return String(localized: "Your score appears after \(time)")
    }

    /// The readiness level only makes sense once a score exists.
    private var isLevelVisible: Bool {
        store.contentState.isReady && !store.isAwaitingSleepData
    }

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
