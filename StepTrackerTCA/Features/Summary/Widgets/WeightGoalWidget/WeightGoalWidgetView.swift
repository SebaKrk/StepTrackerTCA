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
    func weightGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            groupBoxTitle(
                "Weight",
                "figure",
                "Avg \(store.averageWeight) kg",
                destination: true
            )
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    var weightGoalChart: some View {
        Chart {
            if let selectedHealthMetric = store.selectedHealthMetric {
                RuleMark(x: .value("Selected Metric", selectedHealthMetric.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .offset(y: -10)
                    .annotation(position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        weightAnnotationView
                    }
            }
            //TODO: - dodać opcje wprowadzania swojego gola
            RuleMark(y: .value("Goal", 98))
                .foregroundStyle(.mint)
                .lineStyle(.init(lineWidth: 1, dash: [5]))
                .annotation(alignment: .bottomLeading) {
                    Text("Weight goal")
                        .bold()
                        .foregroundStyle(.mint)
                        .font(.caption)
                }
            ForEach(store.weightData) { weight in
                AreaMark(
                    x: .value("Day", weight.date, unit: .day),
                    yStart: .value("Value", weight.value),
                    yEnd: .value("Min value", store.weightMinValue)
                )
                .foregroundStyle(Gradient(colors: [.indigo.opacity(0.5), .clear]))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Day", weight.date, unit: .day),
                    y: .value("Value", weight.value)
                )
                .foregroundStyle(.indigo)
                .interpolationMethod(.catmullRom)
                .symbol(.circle)
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
    var weightAnnotationView: some View {
        VStack(alignment: .leading) {
            Text(store.selectedHealthMetric?.date ?? .now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            
            Text(store.selectedHealthMetric?.value ?? 0, format: .number.precision(.fractionLength(1)))
                .fontWeight(.heavy)
                .foregroundStyle(.indigo)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
    
    @ViewBuilder
    private func groupBoxTitle(_ title: String, _ systemImage: String, _ secondaryText: String, destination: Bool = true) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(.indigo)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if destination {
                Button {
                    send(.tapDestination)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
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
