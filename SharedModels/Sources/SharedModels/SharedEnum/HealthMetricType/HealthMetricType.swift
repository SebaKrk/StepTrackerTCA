//
//  HealthMetricType.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import Foundation

public enum HealthMetricType: String, CaseIterable, Identifiable, Sendable {
    
    case rhr
    case hrv
    case sleep
    case activity
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .rhr: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "bed.double.fill"
        case .activity: return "flame.fill"
        }
    }
    
    public var title: String {
        switch self {
        case .rhr:
            return String(localized: "RHR", bundle: .module)
        case .hrv:
            return String(localized: "HRV", bundle: .module)
        case .sleep:
            return String(localized: "Sleep", bundle: .module)
        case .activity:
            return String(localized: "Activity", bundle: .module)
        }
    }
    
    public var fullName: String {
        switch self {
        case .rhr:
            return String(localized: "Resting Heart Rate", bundle: .module)
        case .hrv:
            return String(localized: "Heart Rate Variability", bundle: .module)
        case .sleep:
            return String(localized: "Sleep Quality", bundle: .module)
        case .activity:
            return String(localized: "Activity Level", bundle: .module)
        }
    }
    
    public var description: String {
        switch self {
        case .rhr:
            return String(localized: "Resting heart rate (RHR) is the number of heartbeats per minute at rest. Lower values usually indicate better cardiovascular fitness and recovery. Apple Watch measures RHR automatically during sleep and rest.", bundle: .module)
            
        case .hrv:
            return String(localized: "Heart rate variability (HRV) measures the time variation between consecutive heartbeats. Higher HRV suggests better nervous-system balance and training readiness. It is one of the best recovery indicators.", bundle: .module)
            
        case .sleep:
            return String(localized: "Sleep quality is scored from time spent in the sleep stages (deep, REM, light). Better sleep improves recovery and training readiness. 7–9 hours are recommended for adults.", bundle: .module)
            
        case .activity:
            return String(localized: "Activity level measures the energy expended during the previous day. Too much activity can negatively affect today's readiness. Monitoring training load helps avoid overtraining.", bundle: .module)
        }
    }
    
    public var unit: String {
        switch self {
        case .rhr: return "bpm"
        case .hrv: return "ms"
        case .sleep: return String(localized: "hours", bundle: .module)
        case .activity: return "kcal"
        }
    }
    
    public var missingDataMessage: String {
        switch self {
        case .rhr:
            return String(localized: "No heart rate data available. Check Health app.", defaultValue: "No heart rate data available. Check Health app.", bundle: .module)
        case .hrv:
            return String(localized: "No HRV data found. Regular measurements required.", defaultValue: "No HRV data found. Regular measurements required.", bundle: .module)
        case .sleep:
            return String(localized: "No sleep data. Track your sleep to see insights.", defaultValue: "No sleep data. Track your sleep to see insights.", bundle: .module)
        case .activity:
            return String(localized: "No calories burned data available.", defaultValue: "No calories burned data available.", bundle: .module)
        }
    }
    
}
