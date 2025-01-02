//
//  DefaultsKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Foundation

/// An enumeration representing keys used in UserDefaults.
///
/// Each case corresponds to a specific key for storing or retrieving data.
public enum DefaultsKey: String, CaseIterable {
    
    /// Key to track whether the user has seen the permission priming screen.
    case hasSeenPermissionPriming = "hasSeenPermissionPriming"
    
}
