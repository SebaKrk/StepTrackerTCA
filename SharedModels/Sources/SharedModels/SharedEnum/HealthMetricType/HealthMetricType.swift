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
        case .rhr: return "RHR"
        case .hrv: return "HRV"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        }
    }
    
    public var fullName: String {
        switch self {
        case .rhr: return "Resting Heart Rate"
        case .hrv: return "Heart Rate Variability"
        case .sleep: return "Sleep Quality"
        case .activity: return "Activity Level"
        }
    }
}
