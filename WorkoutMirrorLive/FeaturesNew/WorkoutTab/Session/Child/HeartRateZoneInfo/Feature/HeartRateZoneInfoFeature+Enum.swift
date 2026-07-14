//
//  HeartRateZoneInfoFeature+Enum.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/12/2025.
//

import Foundation
import SharedModels

/// Implementation of `HeartRateZoneInfoFeature` enums
extension HeartRateZoneInfoFeature {
    
    /// Display mode for the heart rate zone info view.
    enum DisplayMode: Equatable {
        /// Shows all heart rate zones.
        case allZones
        /// Shows only a single specified zone.
        case singleZone(HeartRateZone)
    }
    
}
