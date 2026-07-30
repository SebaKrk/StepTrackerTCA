//
//  StatsFeature+Enums.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import Foundation

extension StatsFeature {
    
    /// Represents different view contexts for the Stats feature
    ///
    /// This enum defines the available tabs/sections in the Stats view,
    /// allowing users to switch between different types of statistical information.
    enum StatsFeatureContext: CaseIterable, Identifiable, Equatable {
        
        /// Today's stats - current status, training readiness, and immediate actionable insights
        case today

        /// Analytics view - historical data, trends, and long-term performance analysis
        case analytics

        /// Exercise analytics - per-exercise tracking, movement balance, progression charts
        case exercises

        /// Unique identifier for the enum case
        var id: Self { self }

        /// Human-readable title for display in the UI
        var title: String {
            switch self {
            case .today:
                return String(localized: "Today", bundle: .main)
            case .analytics:
                return String(localized: "Analytics", bundle: .main)
            case .exercises:
                return String(localized: "Exercises", bundle: .main)
            }
        }
        
    }

}

