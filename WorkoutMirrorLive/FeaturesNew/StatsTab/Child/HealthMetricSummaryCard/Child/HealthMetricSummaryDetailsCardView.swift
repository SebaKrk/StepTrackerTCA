//
//  HealthMetricSummaryDetailsCardView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import Charts
import SharedModels
import SwiftUI

@ViewAction(for: HealthMetricSummaryDetailsCardFeature.self)
struct HealthMetricSummaryDetailsCardView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthMetricSummaryDetailsCardFeature>
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch store.viewState {
            case .success:
                rootView
            case .failed:
                Text("Bladb")
            case .loading:
                ProgressView()
            }
        }
        .navigationTitle("\(store.metricType.title) details")
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    private var rootView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("\(store.initialData.currentValue, specifier: "%.0f") \(store.initialData.unit)")
                    .font(.largeTitle)
                
                if !store.historicalValues.isEmpty {
                    Chart {
                        ForEach(store.historicalValues) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                        }
                    }
                    .frame(height: 200)
                }
                
                Text(store.metricType.description)
            }
            .padding()
        }
    }
    
}
