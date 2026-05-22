//
//  StatsFeature+CancelID.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 29/01/2026.
//

import Foundation

extension StatsFeature {
    
    nonisolated enum StatsFeatureCancelID: Hashable, Sendable {
        case observation

        /// Cancellation ID for the pull-to-refresh "blocking" effect that waits
        /// until all child features signal `.delegate(.refreshDidComplete)`.
        case refresh
    }
    
}
