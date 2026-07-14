//
//  ActivityChartView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI
import Charts
import SharedModels

/// A reusable chart view that displays hourly activity data for different activity types.
///
/// This view provides:
/// - Interactive hour selection with visual feedback (RuleMark)
/// - Automatic filtering to show only data up to current hour
/// - Visual distinction between active and inactive hours using opacity
/// - Responsive scaling based on actual data values
///
/// - Note: For "stand" activity, bar height is constant but opacity indicates activity presence.
/// - Note: For "move" and "exercise", bars with zero values show minimal height with reduced opacity.
struct ActivityChartView: View {
    
    // MARK: - Properties
    
    /// Array of hourly activity data to display
    let hourlyData: [HourlyActivityData]
    
    /// Currently selected hour (0-23), if any
    let selectedHour: Int?
    
    /// Type of activity being displayed (move, exercise, or stand)
    let activityType: ActivityType
    
    /// Callback invoked when user selects or deselects an hour
    let onHourSelected: (Int?) -> Void
    
    // MARK: - Computed Properties
    
    /// Current hour of the day (0-23)
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    /// Filtered data showing only hours up to and including the current hour
    private var visibleData: [HourlyActivityData] {
        hourlyData.filter { $0.hour <= currentHour }
    }
    
    /// Maximum value in the visible dataset, used for chart scaling
    /// Returns a minimum of 10.0 if all values are zero to maintain chart visibility
    private var maxValue: Double {
        let values = visibleData.map { activityType.getValue(from: $0) }
        let maxVal = values.max() ?? 1.0
        return maxVal > 0 ? maxVal : 10.0
    }
    
    // MARK: - Body
    
    var body: some View {
        Chart {
            /// Selection indicator
            if let selectedHour {
                RuleMark(x: .value("Selected Hour", selectedHour))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            
            /// Activity bars
            ForEach(visibleData) { data in
                BarMark(
                    x: .value("Hour", data.hour),
                    y: .value("Value", displayValue(for: data))
                )
                .foregroundStyle(barStyle(for: data))
                .cornerRadius(4)
            }
        }
        .chartXSelection(value: .init(
            get: { selectedHour },
            set: { onHourSelected($0) }
        ))
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
        .chartXScale(domain: 0...23)
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
        .frame(height: 90)
        .padding(.vertical, 4)
        .padding(.trailing, 50)
        .overlay(alignment: .trailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Spacer()
                Text("0 \(activityType.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .frame(width: 50)
        }
    }
    
    // MARK: - Private Methods
    
    /// Calculates the display value for a data point
    ///
    /// - Parameter data: The hourly activity data
    /// - Returns: Display value where zero values show as minimal visible bars (except for stand which is constant)
    private func displayValue(for data: HourlyActivityData) -> Double {
        let value = activityType.getValue(from: data)
        
        /// Stand hours are always displayed at constant height
        if activityType == .stand {
            return 1.0
        }
        
        /// Show minimal bar for zero values to maintain visibility
        return value == 0 ? maxValue * 0.025 : value
    }
    
    /// Determines the visual style (color and opacity) for a bar
    ///
    /// - Parameter data: The hourly activity data
    /// - Returns: Shape style with appropriate color and opacity based on activity presence
    private func barStyle(for data: HourlyActivityData) -> AnyShapeStyle {
        let value = activityType.getValue(from: data)
        
        switch activityType {
        case .stand:
            /// Stand: reduced opacity indicates no activity
            let opacity = value == 0 ? 0.2 : 1.0
            return AnyShapeStyle(activityType.color.gradient.opacity(opacity))
            
        case .move, .exercise:
            /// Move/Exercise: reduced opacity for zero values
            let opacity = value == 0 ? 0.2 : 0.9
            return AnyShapeStyle(activityType.color.gradient.opacity(opacity))
        }
    }
}

// MARK: - Activity Type

extension ActivityChartView {
    
    /// Defines the type of activity data being displayed
    enum ActivityType {
        /// Active energy burned (calories)
        case move
        
        /// Exercise minutes
        case exercise
        
        /// Stand hours (binary: 0 or 1 per hour)
        case stand
        
        /// Color associated with the activity type
        var color: Color {
            switch self {
            case .move: return .pink
            case .exercise: return .green
            case .stand: return .cyan
            }
        }
        
        /// Unit of measurement for the activity type
        var unit: String {
            switch self {
            case .move: return "kcal"
            case .exercise: return "min"
            case .stand: return "godz."
            }
        }
        
        /// Extracts the relevant value from hourly activity data
        ///
        /// - Parameter data: The hourly activity data
        /// - Returns: The numeric value for this activity type
        func getValue(from data: HourlyActivityData) -> Double {
            switch self {
            case .move: return data.activeEnergyBurned
            case .exercise: return data.exerciseMinutes
            case .stand: return Double(data.standHours)
            }
        }
    }
}
