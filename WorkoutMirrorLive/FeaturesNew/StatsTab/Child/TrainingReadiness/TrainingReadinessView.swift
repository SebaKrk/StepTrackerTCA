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
            charts
        } label: {
            HStack {
                Text("Training Readiness")
                    .font(.caption)
                Spacer()
                if case .ready = store.contentState {
                    Text(store.readinessLabel)
                        .foregroundStyle(store.readinessLevel.color)
                }
            }
        }
        .backgroundStyle(.clear)
        .foregroundStyle(.secondary)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
            .fill(Color(.secondarySystemBackground).gradient.opacity(0.5)))
        .frame(height: 120)
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
                 // send(.retryButtonTapped)
             })

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
            AxisMarks(values: [0, 25, 50, 75, 90, 100]) { _ in
                AxisValueLabel()
                    .font(.footnote)
                    .foregroundStyle(.primary)
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
