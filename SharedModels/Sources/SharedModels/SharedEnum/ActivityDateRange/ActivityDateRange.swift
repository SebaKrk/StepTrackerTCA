//
//  ActivityDateRange.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 20/12/2025.
//

import Foundation

public enum ActivityDateRange: Int, CaseIterable, Identifiable {
    
    case week = 7
    case twoWeeks = 14
    case month = 28
    case threeMonths = 90
    case year = 365
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .week:
            return String(localized: "7 Days", bundle: .module)
        case .twoWeeks:
            return String(localized: "14 Days", bundle: .module)
        case .month:
            return String(localized: "28 Days", bundle: .module)
        case .threeMonths:
            return String(localized: "3 Months", bundle: .module)
        case .year:
            return String(localized: "Year", bundle: .module)
        }
    }
}
