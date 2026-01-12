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
                Text("Blad")
            case .loading:
                ProgressView()
            }
        }
        .navigationTitle(store.metricType.title)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    //    private var rootView: some View {
    //        ScrollView {
    //            VStack(spacing: 20) {
    //                Text("\(store.initialData.currentValue, specifier: "%.0f") \(store.initialData.unit)")
    //                    .font(.largeTitle)
    //
    //                if !store.historicalValues.isEmpty {
    //                    Chart {
    //                        ForEach(store.historicalValues) { point in
    //                            LineMark(
    //                                x: .value("Date", point.date),
    //                                y: .value("Value", point.value)
    //                            )
    //                        }
    //                    }
    //                    .frame(height: 200)
    //                }
    //
    //                Text(store.metricType.description)
    //            }
    //            .padding()
    //        }
    //    }
    
    private var rootView: some View {
        ScrollView {
            VStack {
                GroupBox {
                    Text("\(store.initialData.currentValue, specifier: "%.0f") \(store.initialData.unit)")
                        .font(.title)
                        .foregroundStyle(.primary)
                } label: {
                    VStack(alignment: .leading) {
                        Text("Score")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Divider()
                    }
                }
                .styledGroupBox()
                .padding(4)
                
                GroupBox {
                    if !store.historicalValues.isEmpty {
                        Chart {
                            // Linia referencyjna bazowej wartości
                            createBaselineRuleMark(baselineValue: store.initialData.baselineValue ?? 0)
                            
                            // Pionowa linia z adnotacją dla wybranego punktu
                            if let selectedPoint = store.selectedDataPoint {
                                createRuleMark(with: selectedPoint) {
                                    ChartAnnotationView(
                                        date: selectedPoint.date,
                                        value: selectedPoint.value,
                                        color: colorForMetric(store.metricType)
                                    )
                                }
                            }
                            
                            // Dane historyczne
                            ForEach(store.historicalValues) { point in
                                createLineMark(
                                    with: point,
                                    color: colorForMetric(store.metricType)
                                )
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) {
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.3))
                                AxisValueLabel()
                            }
                        }
                        .frame(height: 250)
                        //                        .padding()
                        //                        .background(
                        //                            RoundedRectangle(cornerRadius: 12)
                        //                                .fill(Color(.secondarySystemBackground))
                        //                        )
                    }
                }
                .styledGroupBox()
                .padding(4)
                
                GroupBox {
                    VStack(spacing: 12) {
                        Text(store.metricType.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: store.metricType.icon)
                            Text(store.metricType.title)
                            Spacer()
                        }
                        .foregroundColor(.gray)
                        .font(.caption)
                        Divider()
                    }
                }
                .styledGroupBox()
                .padding(4)
                
                
            }
            .padding()
        }
    }
    
}


struct ChartAnnotationView: View {
    
    // MARK: - Properties
    
    let date: Date
    let value: Double
    let color: Color
    
    // MARK: - Lifecycle
    
    init(date: Date, value: Double, color: Color) {
        self.date = date
        self.value = value
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            dateLabel
            valueLabel
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
    
    // MARK: - Subview
    
    private var dateLabel: some View {
        Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
            .font(.footnote.bold())
            .foregroundStyle(.secondary)
    }
    
    private var valueLabel: some View {
        Text(value, format: .number.precision(.fractionLength(1)))
            .fontWeight(.heavy)
            .foregroundStyle(color)
    }
    
}
