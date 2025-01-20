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
    func stepsWalkGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            groupBoxTitle(
                "Steps",
                "figure.walk",
                "Avg: \(Int(store.avgStepCount)) steps",
                destination: true
            )
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    var stepWalkChart: some View {
        Chart {
            if let selectedHealthMetric = store.selectedHealthMetric {
                RuleMark(x: .value("Selected Metric", selectedHealthMetric.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .offset(y: -10)
                    .annotation(position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView }
            }
            
            RuleMark(y: .value("Average", store.avgStepCount))
                .foregroundStyle(Color.secondary)
                .lineStyle(.init(lineWidth: 1, dash: [5]))
            
            ForEach(store.stepData) { steps in
                BarMark(
                    x: .value("Date", steps.date, unit: .day),
                    y: .value("Steps", steps.value)
                )
                .opacity(store.rawSelectedDate == nil || steps.date == store.selectedHealthMetric?.date ? 1.0 : 0.3)
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
    var annotationView: some View {
        VStack(alignment: .leading) {
            Text(store.selectedHealthMetric?.date ?? .now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            
            Text(store.selectedHealthMetric?.value ?? 0, format: .number.precision(.fractionLength(0)))
                .fontWeight(.heavy)
                .foregroundStyle(.pink)
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
                    .foregroundStyle(.pink)
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
        ContentUnavailableView("Brak danych",
                               systemImage: "exclamationmark.triangle",
                               description: Text("Nie znaleziono żadnych danych. Dodaj nowe dane, aby je zobaczyć."))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
    }
    
}

#Preview {
    NavigationStack {
        StepWidgetView(store: Store(initialState: StepWidgetFeature.State(stepData: MockData.steps), reducer: {
            StepWidgetFeature(service: DefaultStepWidgetService() )
        }))
    }
}
