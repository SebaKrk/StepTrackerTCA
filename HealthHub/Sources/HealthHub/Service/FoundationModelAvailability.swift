//
//  FoundationModelAvailability.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 09/02/2026.
//

import Foundation

/// Checks whether on-device Foundation Models are available on this device.
///
/// Foundation Models require iPhone 15 Pro+ or M-series iPad/Mac
/// running iOS 26.0+. Used by ``WorkoutExtractionClient`` to select
/// the appropriate workout extraction strategy at runtime.
public enum FoundationModelAvailability {

    /// Returns `true` if on-device Foundation Models can be used.
    public static var isAvailable: Bool {
        // TODO: Check actual FoundationModels framework availability
        // when building with iOS 26 SDK.
        false
    }
}
