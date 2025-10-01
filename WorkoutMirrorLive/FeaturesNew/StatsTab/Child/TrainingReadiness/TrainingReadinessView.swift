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
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingReadinessFeature>
    
    // MARK: - View
    
    var body: some View {
            GroupBox {
                content
            } label: {
                HStack {
                    Text("Training Readiness")
                    Spacer()
                    Text(store.readinessLabel)
                        .foregroundStyle(store.readinessLevel.color)
                }
            }
            .padding([.leading, .trailing], 8)
            .foregroundStyle(.secondary)
            .frame(height: 120)
            .skeleton(isLoading: store.contentState == .loading) 
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            switch store.contentState {
            case .loading:
                skeletonView
            case .success:
                charts
            case .unauthorized:
                Text("")
            case .locked:
                Text("")
            case .error:
                Text("")
            }
        }
        .frame(height: 60)
    }
    
    
    @ViewBuilder
    private var charts: some View {
        Chart {
            readinessChart()
            readinessIndicator(store.readinessValue)
                .annotation(position: .top, alignment: .center, spacing: -10) {
                    readinessLabel(value: store.readinessValue,
                                   color: store.readinessLevel.color)
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
            plotArea
                .frame(height: 10)
        }
        
    }
    
    private var skeletonView: some View {
        charts
    }
    
}

