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
                Spacer()
                if case .success = store.contentState {
                    Text(store.readinessLabel)
                        .foregroundStyle(store.readinessLevel.color)
                }
            }
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
        .frame(height: 120)
        .skeleton(isLoading: store.contentState == .loading)
        .overlay { overlayContent }
        .onAppear {
            send(.viewDidAppear)
        }
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
        .blur(radius: shouldBlur ? 3 : 0)
        .opacity(shouldBlur ? 0.4 : 1.0)
    }

    private var shouldBlur: Bool {
         switch store.contentState {
         case .locked, .unauthorized, .error:
             return true
         case .loading, .success:
             return false
         }
     }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch store.contentState {
        case .locked:
            ChartOverlayView.locked {
                ///send(.unlockButtonTapped)
            }
        case .unauthorized:
            ChartOverlayView.unauthorized {
                //send(.requestHealthAccessTapped)
            }
        case .error:
            ChartOverlayView.error {
                //send(.retryButtonTapped)
            }
        default:
            EmptyView()
        }
    }
    
}
