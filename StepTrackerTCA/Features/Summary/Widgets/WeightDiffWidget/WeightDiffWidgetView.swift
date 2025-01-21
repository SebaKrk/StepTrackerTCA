//
//  WeightDiffWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import ComposableArchitecture
import Charts
import SwiftUI

@ViewAction(for: WeightDiffWidgetFeature.self)
struct WeightDiffWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightDiffWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            if !store.weightData.isEmpty {
                weightDiffGroupBox { weightDiffBarChart }
            } else {
                weightDiffGroupBox { contentUnavailable }
            }
        }
        .frame(height: 300)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private func weightDiffGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            headerTitle
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var weightDiffBarChart: some View {
        Chart {
            if let selectedHealthMetric = store.selectedHealthMetric {
                createRuleMark(with: selectedHealthMetric) { annotationView }
            }
            ForEach(store.weightDataPerWeekDay) { weightDiff in
                createWeightDiffBarMark(with: weightDiff)
            }
        }
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisValueLabel(format: .dateTime.weekday(), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
    
    private var annotationView: some View {
        ChartAnnotationView(
            date: store.selectedHealthMetric?.date ?? .now,
            value: store.selectedHealthMetric?.value ?? 0,
            color: (store.selectedHealthMetric?.value ?? 0) >= 0 ? .indigo : .mint
        )
    }
    
    @ViewBuilder
    private var headerTitle: some View {
        ChartGroupBoxHeader(
            title: "Average Weight Change",
            systemImage: "figure",
            secondaryText: "Per Weekday (Last 28 Days)",
            color: .indigo
        )
    }
    
    @ViewBuilder
    private var contentUnavailable: some View {
        ChartContentUnavailable()
    }
    
}
