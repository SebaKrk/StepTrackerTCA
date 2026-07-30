//
//  HeartRateZoneInfoFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `HeartRateZoneInfoFeature` state
extension HeartRateZoneInfoFeature {
    
    @ObservableState
    struct State {
        
        /// Currently selected zone for description expansion.
        var selectedZone: HeartRateZone?
        
        /// A Boolean value indicating whether the description view is expanded.
        var descriptionIsExpanded: Bool = false
        
        /// Display mode determining which zones to show.
        var displayMode: DisplayMode = .allZones
        
        /// Zones to display based on current display mode.
        var zonesToDisplay: [HeartRateZone] {
            switch displayMode {
            case .allZones:
                return HeartRateZone.allCases
            case .singleZone(let zone):
                return [zone]
            }
        }
    }
    

}

