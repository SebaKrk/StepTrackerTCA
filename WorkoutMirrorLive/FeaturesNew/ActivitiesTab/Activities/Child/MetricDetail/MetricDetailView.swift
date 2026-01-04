//
//  MetricDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: MetricDetailFeature.self)
struct MetricDetailView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MetricDetailFeature>
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack {
                valueSection
                scaleSection
                scoreSection
                metricInfoSection
            }
            .padding([.leading, .trailing], 8)
        }
        .navigationTitle(store.metricType.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(LinearGradient(colors: [levelColor.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    // MARK: - Value Section
    
    // MARK: - Value Section

    private var valueSection: some View {
        GroupBox {
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedValue)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(levelColor)
                    
                    if !formattedUnit.isEmpty {
                        Text(formattedUnit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .styledGroupBox()
        .padding(4)
    }
    
    // MARK: - Scale Section
    
    private var scaleSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                scaleView
            }
        } label: {
            VStack(alignment: .leading) {
                Text("Scale")
                    .font(.headline)
                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }
    
    @ViewBuilder
    private var scaleView: some View {
        switch store.metricType {
        case .hrTSS:
            MetricScaleView(
                levels: HRTSSLevel.allCases.map { ($0.rawValue, $0.color) },
                currentIndex: HRTSSLevel.allCases.firstIndex(of: currentHRTSSLevel) ?? 0
            )
        case .intensity:
            MetricScaleView(
                levels: IntensityFactorLevel.allCases.map { ($0.rawValue, $0.color) },
                currentIndex: IntensityFactorLevel.allCases.firstIndex(of: currentIntensityLevel) ?? 0
            )
        case .hrRecovery:
            MetricScaleView(
                levels: HRRecoveryLevel.allCases.map { ($0.rawValue, $0.color) },
                currentIndex: HRRecoveryLevel.allCases.firstIndex(of: currentHRRecoveryLevel) ?? 0
            )
        case .recoveryDemand:
            MetricScaleView(
                levels: RecoveryDemandLevel.allCases.map { ($0.rawValue, $0.color) },
                currentIndex: RecoveryDemandLevel.allCases.firstIndex(of: currentRecoveryDemandLevel) ?? 0
            )
        }
    }
    
    // MARK: - Score Section
    
    private var scoreSection: some View {
        GroupBox {
            Text(levelDescription)
                .font(.body)
                .foregroundColor(.secondary)
        } label: {
            VStack(alignment: .leading) {
                Text("Your Score")
                    .font(.headline)
                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }
    
    // MARK: - Metric Info Section
    
    private var metricInfoSection: some View {
        GroupBox {
            Text(store.metricType.metricDescription)
                .font(.body)
                .foregroundColor(.secondary)
        } label: {
            VStack(alignment: .leading) {
                Text("What is \(store.metricType.title)?")
                    .font(.headline)
                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }
    
    // MARK: - Computed Properties
    
    private var formattedValue: String {
        switch store.metricType {
        case let .hrTSS(value, _):
            return "\(Int(value))"
        case let .intensity(value, _):
            return String(format: "%.2f", value)
        case let .hrRecovery(value, _):
            return "\(value)"
        case let .recoveryDemand(_, level):
            return level.valueString
        }
    }
    
    private var levelName: String {
        switch store.metricType {
        case let .hrTSS(_, level): return level.rawValue
        case let .intensity(_, level): return level.rawValue
        case let .hrRecovery(_, level): return level.rawValue
        case let .recoveryDemand(_, level): return level.rawValue
        }
    }
    
    private var levelColor: Color {
        switch store.metricType {
        case let .hrTSS(_, level): return level.color
        case let .intensity(_, level): return level.color
        case let .hrRecovery(_, level): return level.color
        case let .recoveryDemand(_, level): return level.color
        }
    }
    
    private var levelDescription: String {
        switch store.metricType {
        case let .hrTSS(_, level): return level.description
        case let .intensity(_, level): return level.description
        case let .hrRecovery(_, level): return level.description
        case let .recoveryDemand(_, level): return level.description
        }
    }

    private var formattedUnit: String {
        switch store.metricType {
        case .hrTSS: return ""
        case .intensity: return ""
        case .hrRecovery: return "bpm"
        case let .recoveryDemand(_, level): return level.unitString
        }
    }
    
    // MARK: - Current Levels (for scale index)
    
    private var currentHRTSSLevel: HRTSSLevel {
        if case let .hrTSS(_, level) = store.metricType { return level }
        return .low
    }
    
    private var currentIntensityLevel: IntensityFactorLevel {
        if case let .intensity(_, level) = store.metricType { return level }
        return .recovery
    }
    
    private var currentHRRecoveryLevel: HRRecoveryLevel {
        if case let .hrRecovery(_, level) = store.metricType { return level }
        return .average
    }
    
    private var currentRecoveryDemandLevel: RecoveryDemandLevel {
        if case let .recoveryDemand(_, level) = store.metricType { return level }
        return .oneDay
    }
}

// MARK: - Scale Component

struct MetricScaleView: View {
    let levels: [(name: String, color: Color)]
    let currentIndex: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<levels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(levels[index].color)
                        .frame(height: index == currentIndex ? 24 : 16)
                        .overlay {
                            if index == currentIndex {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.primary, lineWidth: 2)
                            }
                        }
                }
            }
            
            HStack {
                ForEach(0..<levels.count, id: \.self) { index in
                    Text(levels[index].name)
                        .font(.caption2)
                        .foregroundColor(index == currentIndex ? .primary : .secondary)
                        .fontWeight(index == currentIndex ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}
