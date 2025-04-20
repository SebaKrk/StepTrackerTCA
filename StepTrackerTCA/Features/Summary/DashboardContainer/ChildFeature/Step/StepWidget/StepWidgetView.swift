//
//  StepWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Charts
import SwiftUI

@ViewAction(for: StepWidgetFeature.self)
struct StepWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StepWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            if !store.stepData.isEmpty {
                stepsWalkGroupBox { stepWalkChart }
            } else {
                stepsWalkGroupBox { contentUnavailable }
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
    private func stepsWalkGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            headerTitle
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var stepWalkChart: some View {
        Chart {
            if let selectedHealthMetric = store.selectedHealthMetric {
                createRuleMark(with: selectedHealthMetric) { annotationView }
            }
            createStepRuleMark()
            
            ForEach(store.stepData) { steps in
                createStepBarMark(for: steps)
            }
        }
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
        .foregroundStyle(.pink)
        .chartXAxis {
            AxisMarks {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel((value.as(Double.self) ?? 0).formatted(.number.notation(.compactName)))
            }
        }
    }
    
    @ViewBuilder
    private var annotationView: some View {
        ChartAnnotationView(
            date: store.selectedHealthMetric?.date ?? .now,
            value: store.selectedHealthMetric?.value ?? 0,
            color: .pink
        )
    }
    
    @ViewBuilder
    private var headerTitle: some View {
        ChartGroupBoxHeader(
            title: "Steps",
            systemImage: "figure.walk",
            secondaryText: "Avg: \(Int(store.avgStepCount)) steps",
            color: .pink,
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
        StepWidgetView(store: Store(initialState: StepWidgetFeature.State(stepData: MockData.steps), reducer: {
            StepWidgetFeature(service: DefaultStepWidgetService() )
        }))
    }
}
