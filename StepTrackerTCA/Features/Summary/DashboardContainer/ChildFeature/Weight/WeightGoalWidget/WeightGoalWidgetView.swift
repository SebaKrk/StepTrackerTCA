//
//  WeightGoalWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Charts
import SwiftUI

@ViewAction(for: WeightGoalWidgetFeature.self)
struct WeightGoalWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightGoalWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            if !store.weightData.isEmpty {
                weightGroupBox { weightGoalChart }
            } else {
                weightGroupBox { contentUnavailable }
            }
        }
        .frame(height: 250)
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.detailList,
                action: \.destination.detailList)) { store in
                    HealthDataListView(store: store)
                }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private func weightGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            headerTitle
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var weightGoalChart: some View {
        Chart {
            if let selectedHealthMetric = store.selectedHealthMetric {
                createRuleMark(with: selectedHealthMetric) { weightAnnotationView }
            }
            if let weightGoal = store.weightGoal {
                createGoalRuleMark(weightGoal)
            }
            ForEach(store.weightData) { weight in
                createWeightAreaMark(with: weight)
                createWeightLineMark(with: weight)
            }
        }
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel()
            }
        }
        
    }
    
    @ViewBuilder
    private var weightAnnotationView: some View {
        ChartAnnotationView(date: store.selectedHealthMetric?.date ?? .now,
                            value: store.selectedHealthMetric?.value ?? 0,
                            color: .indigo)
    }
    
    @ViewBuilder
    private var headerTitle: some View {
        ChartGroupBoxHeader(
            title: "Weight",
            systemImage: "figure",
            secondaryText:  "Avg \(store.averageWeight) kg",
            color: .indigo,
            destination: true) {
                send(.tapDestination)
            }
    }
    
    @ViewBuilder
    private var contentUnavailable: some View {
        ChartContentUnavailable()
    }
}

#Preview {
    NavigationStack {
        WeightGoalWidgetView(store: Store(initialState: WeightGoalWidgetFeature.State(weightData: MockData.weights), reducer: {
            WeightGoalWidgetFeature(service: DefaultWeightGoalWidgetService() )
        }))
    }
}
