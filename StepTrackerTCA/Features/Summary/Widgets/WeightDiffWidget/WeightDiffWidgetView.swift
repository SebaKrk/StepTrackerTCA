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
                RuleMark(x: .value("Selected Data", selectedHealthMetric.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .offset(y: -10)
                    .annotation(position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView }
            }
            
            ForEach(store.weightDataPerWeekDay) { weightDiff in
                BarMark(
                    x: .value("Date", weightDiff.date, unit: .day),
                    y: .value("Weight Diff", weightDiff.value)
                )
                .foregroundStyle(weightDiff.value >= 0 ? Color.indigo.gradient : Color.mint.gradient)
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
        VStack(alignment: .leading) {
            Text(store.selectedHealthMetric?.date ?? .now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            
            Text(store.selectedHealthMetric?.value ?? 0, format: .number.precision(.fractionLength(2)))
                .fontWeight(.heavy)
                .foregroundStyle((store.selectedHealthMetric?.value ?? 0) >= 0 ? .indigo : .mint)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
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
