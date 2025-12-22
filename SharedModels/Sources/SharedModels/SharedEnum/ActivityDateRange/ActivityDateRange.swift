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
        case .week: return "7 Days"
        case .twoWeeks: return "14 Days"
        case .month: return "28 Days"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
}
