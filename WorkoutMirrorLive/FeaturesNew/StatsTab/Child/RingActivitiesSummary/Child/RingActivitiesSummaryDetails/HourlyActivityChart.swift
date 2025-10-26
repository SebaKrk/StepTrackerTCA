//
//  HourlyActivityChart.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI
import Charts
import SharedModels

struct HourlyActivityChart: View {
    
    let hourlyData: [HourlyActivityData]
    let dataType: ActivityDataType
    let totalValue: Double
    let goalValue: Double
    
    enum ActivityDataType {
        case move
        case exercise
        case stand
        
        var color: Color {
            switch self {
            case .move: return .pink
            case .exercise: return .green
            case .stand: return .cyan
            }
        }
        
        var unit: String {
            switch self {
            case .move: return "kcal"
            case .exercise: return "min"
            case .stand: return "godz."
            }
        }
    }
    
    // ✅ Oblicz obecną godzinę
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    // ✅ Filtruj dane tylko do obecnej godziny (włącznie)
    private var visibleData: [HourlyActivityData] {
        hourlyData.filter { $0.hour <= currentHour }
    }
    
    var body: some View {
        Chart(visibleData) { data in
            BarMark(
                x: .value("Hour", data.hour),
                y: .value("Value", displayValue(for: data))
            )
            .foregroundStyle(barColor(for: data))
            .cornerRadius(2)
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(String(format: "%02d", hour))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxValue * 1.1))
        .chartXScale(domain: 0...23) // ✅ Pokaż całą oś X (0-23), ale rysuj tylko do currentHour
        .chartPlotStyle { plotArea in
            plotArea
                .background(.clear)
        }
        .frame(height: 90)
        .padding(.vertical, 4)
        .padding(.trailing, 50) // Miejsce na etykietę po prawej
        .overlay(alignment: .trailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Spacer()
                Text("0 \(dataType.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .frame(width: 50)
        }
    }
    
    // Oblicz maksymalną wartość dla danego typu danych (tylko z widocznych danych)
    private var maxValue: Double {
        let values = visibleData.map { dataValue(for: $0) }
        let maxVal = values.max() ?? 1.0
        // ✅ Jeśli wszystkie wartości to 0, zwróć sensowną wartość minimalną
        return maxVal > 0 ? maxVal : 10.0
    }
    
    // Zwróć wartość do wyświetlenia
    private func displayValue(for data: HourlyActivityData) -> Double {
        let value = dataValue(for: data)
        
        // Dla stand zawsze zwracaj 1 (wysokość będzie stała)
        if dataType == .stand {
            return 1.0
        }
        
        // Dla move i exercise: jeśli 0, pokaż mały słupek
        return value == 0 ? maxValue * 0.025 : value
    }
    
    private func barColor(for data: HourlyActivityData) -> AnyShapeStyle {
        let value = dataValue(for: data)
        
        switch dataType {
        case .stand:
            // Jeśli stand = 0, opacity 0.2, jeśli 1, opacity 1.0
            let opacity = value == 0 ? 0.2 : 1.0
            return AnyShapeStyle(dataType.color.gradient.opacity(opacity))
        case .move, .exercise:
            // Dla move i exercise też zmniejsz opacity gdy 0
            let opacity = value == 0 ? 0.2 : 1.0
            return AnyShapeStyle(dataType.color.gradient.opacity(opacity))
        }
    }
    
    private func dataValue(for data: HourlyActivityData) -> Double {
        switch dataType {
        case .move:
            return data.activeEnergyBurned
        case .exercise:
            return data.exerciseMinutes
        case .stand:
            return Double(data.standHours)
        }
    }
}
