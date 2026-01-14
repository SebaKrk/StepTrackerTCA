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
                errorView
            case .loading:
                ProgressView()
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
        
    }
    
    // MARK: - Computed Properties
    
    /// Dynamiczny kolor bazowany na wyniku (score)
    private var scoreColor: Color {
        colorForScore(store.initialData.score, data: store.initialData)
    }
    
    /// Średnia wartość z całego tygodnia
    private var weeklyAverage: Double {
        guard !store.historicalValues.isEmpty else { return 0 }
        let sum = store.historicalValues.reduce(0.0) { $0 + $1.value }
        return sum / Double(store.historicalValues.count)
    }
    
    private var rootView: some View {
        ScrollView {
            VStack(spacing: 2) {
                descriptionView
                metricsSummaryView
                chartView
                averageView
            }
            .padding()
        }
        .background(LinearGradient(colors: [scoreColor.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    private var metricsSummaryView: some View {
        HStack(spacing: 4) {
            metricCard(title: String(localized: "Value")) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatValue(store.initialData.currentValue, unit: store.initialData.unit))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(store.initialData.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            metricCard(title: String(localized: "Status")) {
                if store.metricType == .activity, let activityStatus = store.initialData.asActivityStatus {
                    HStack(spacing: 4) {
                        Image(systemName: activityStatus.icon)
                            .foregroundColor(activityStatus.color)
                            .font(.caption)
                        Text(activityStatus.title)
                            .font(.caption)
                            .foregroundColor(activityStatus.color)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: store.initialData.status.icon)
                            .foregroundColor(store.initialData.status.color)
                            .font(.caption)
                        Text(store.initialData.status.text)
                            .font(.caption)
                            .foregroundColor(store.initialData.status.color)
                    }
                }
            }
            
            metricCard(title: String(localized: "Score")) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(store.initialData.score)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(4)
    }
    
    private var chartView: some View {
        GroupBox {
            if !store.historicalValues.isEmpty {
                Chart {
                    // Linia referencyjna bazowej wartości
                    createBaselineRuleMark(baselineValue: store.initialData.baselineValue ?? 0)
                    
                    // Linia średniej tygodniowej
                    createAverageRuleMark(averageValue: weeklyAverage)
                    
                    // Pionowa linia z adnotacją dla wybranego punktu
                    if let selectedPoint = store.selectedDataPoint {
                        createRuleMark(with: selectedPoint) {
                            ChartAnnotationView(
                                date: selectedPoint.date,
                                value: selectedPoint.value,
                                color: scoreColor
                            )
                        }
                    }
                    
                    // Dane historyczne
                    ForEach(store.historicalValues) { point in
                        createLineMark(
                            with: point,
                            color: scoreColor
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
            }
        } label: {
            VStack(alignment: .leading) {
                headerTitleDates
                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }
    
    private var averageView: some View {
        GroupBox {
            HStack(spacing: 0) {
                Text("Weekly average:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                HStack {
                    Text(weeklyAverage, format: .number.precision(.fractionLength(1)))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(store.initialData.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .styledGroupBox()
        .padding(4)
    }
    
    
    private var headerTitleDates: some View {
        HStack {
            Text(chartDateRange.start, format: .dateTime.day().month())
            Text("-")
            Text(chartDateRange.end, format: .dateTime.day().month().year())
            Spacer()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    private var descriptionView: some View {
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
    
    private var errorView: some View {
        ContentUnavailableView("No Data",
                               systemImage: "exclamationmark.triangle.fill",
                               description: Text("It was not possible to retrieve the health metrics data. Please try again later."))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
        
    }
    
    private var chartDateRange: (start: Date, end: Date) {
        let dates = store.historicalValues.map { $0.date }
        let minDate = dates.min() ?? Date()
        let maxDate = dates.max() ?? Date()
        
        return (minDate, maxDate)
    }
    
    // MARK: - Helpers
    
    /// Formats value based on unit type - kcal without decimals, others with 1 decimal
    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == "kcal" {
            return String(format: "%.0f", value)  // Calories: 652 (not 652.1)
        } else {
            return String(format: "%.1f", value)   // Others: 66.1 ms, 7.3 hours
        }
    }
    
    // MARK: - Helper Views
    
    /// Generic metric card with custom content
    @ViewBuilder
    private func metricCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
            }
        }
        .styledGroupBox()
        .frame(height: 100)
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
