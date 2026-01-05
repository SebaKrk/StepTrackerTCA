//
//  HealthMetricType.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import Foundation

public enum HealthMetricType: String, CaseIterable, Identifiable {
    
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
}
