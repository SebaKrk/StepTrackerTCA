//
//  RecoveryDemandLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import SwiftUI

/// Recovery Demand classification based on estimated recovery hours.
public enum RecoveryDemandLevel: CaseIterable, Identifiable, Sendable {
    
    case readySoon      // < 12h
    case oneDay         // 12-24h
    case twoDays        // 24-48h
    case threeDays      // 48-72h
    case extended       // > 72h
    
    public var id: String { title }
    
    /// Title key for localization
    public var title: String {
        switch self {
        case .readySoon: return String(localized: "Ready Soon", bundle: .module)
        case .oneDay: return String(localized: "Moderate", bundle: .module)
        case .twoDays: return String(localized: "Significant", bundle: .module)
        case .threeDays: return String(localized: "High", bundle: .module)
        case .extended: return String(localized: "Very High", bundle: .module)
        }
    }
    
    // MARK: - Factory
    
    public static func from(hours: Double) -> RecoveryDemandLevel {
        switch hours {
        case ..<12: return .readySoon
        case 12..<24: return .oneDay
        case 24..<48: return .twoDays
        case 48..<72: return .threeDays
        default: return .extended
        }
    }
    
    // MARK: - Display Properties
    
    public var color: Color {
        switch self {
        case .readySoon: return .green
        case .oneDay: return .mint
        case .twoDays: return .yellow
        case .threeDays: return .orange
        case .extended: return .red
        }
    }
    
    
    public var description: String {
        switch self {
        case .readySoon:
            return String(
                localized: "Light session. You'll be ready for another hard workout soon.",
                bundle: .module
            )
        case .oneDay:
            return String(
                localized: "Moderate effort. Allow ~24 hours before next hard session.",
                bundle: .module
            )
        case .twoDays:
            return String(
                localized: "Significant stress. Consider 1-2 days of easy training.",
                bundle: .module
            )
        case .threeDays:
            return String(
                localized: "High training load. Plan 2-3 days of recovery or light work.",
                bundle: .module
            )
        case .extended:
            return String(
                localized: "Very demanding session. Full recovery may take 3+ days.",
                bundle: .module
            )
        }
    }
    
    // W RecoveryDemandLevel
    public var valueString: String {
        switch self {
        case .readySoon: return "<12"
        case .oneDay: return "~1"
        case .twoDays: return "1-2"
        case .threeDays: return "2-3"
        case .extended: return "3+"
        }
    }
    
    public var unitString: String {
        switch self {
        case .readySoon:
            return String(
                localized: "hours",
                bundle: .module
            )
        case .oneDay:
            return String(
                localized: "day",
                bundle: .module
            )
            
        default:  return String(
            localized: "day",
            bundle: .module
        )}
    }
    
}
