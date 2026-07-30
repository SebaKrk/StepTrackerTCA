//
//  CancelId.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import Foundation

/// Identifiers for cancellable effects used in the workout session feature.
///
/// These are used to manage long-running streams such as session state and metrics updates.
public enum CancelId: Hashable {
    
    /// Cancellation ID for the workout session running state stream.
    case cancelSessionRunning
    
    /// Cancellation ID for the workout metrics stream.
    case cancelMetrics
    
}
