//
//  WorkoutParsingStrategyFactory.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Builds the ``WorkoutParsingStrategy`` for a chosen ``WorkoutParsingBackend``.
///
/// The only place that knows which concrete strategy backs each case,
/// so the feature layer depends on the enum and the protocol alone.
public enum WorkoutParsingStrategyFactory {

    /// - Parameter proxy: Transport to the server-side proxy; ignored by on-device backends.
    public static func make(
        _ backend: WorkoutParsingBackend,
        proxy: ScanProxyClient
    ) -> any WorkoutParsingStrategy {
        switch backend {
        case .claudeText, .claudeVision, .claudeVisionWithOCRHint:
            return ProxyStrategy(backend: backend, proxy: proxy)
        }
    }
}
