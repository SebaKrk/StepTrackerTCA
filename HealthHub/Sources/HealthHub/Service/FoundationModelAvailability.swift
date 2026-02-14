//
//  FoundationModelAvailability.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 09/02/2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Checks whether on-device Foundation Models are available on this device.
///
/// Foundation Models require an Apple Intelligence-compatible device
/// (iPhone 15 Pro+, M-series iPad/Mac) running iOS 26.0+
/// with Apple Intelligence enabled. Used by ``WorkoutExtractionClient``
/// to select the appropriate workout extraction strategy at runtime.
///
/// Possible unavailability reasons:
/// - Device not eligible (no Apple Intelligence support)
/// - Apple Intelligence not enabled in Settings
/// - Model not yet downloaded after enabling Apple Intelligence
public enum FoundationModelAvailability {

    /// Returns `true` if on-device Foundation Models can be used.
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            return availability == .available
        }
        #endif
        return false
    }
}
