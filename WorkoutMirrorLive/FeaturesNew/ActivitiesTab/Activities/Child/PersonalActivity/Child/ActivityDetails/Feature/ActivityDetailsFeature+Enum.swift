//
//  ActivityDetailsFeature+Enum.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 22/11/2026.
//

/// Implementation of `ActivityDetailsFeature` recap-map gate.
extension ActivityDetailsFeature {

    /// A load that must finish before the recap map may mount.
    enum RecapMapLoad: Hashable {

        /// GPS route or single pin of the workout.
        case location

        /// Performance metric cards.
        case metrics

        /// GymRoom class recap.
        case recap

        /// Heart-rate zones with effort points.
        case zones
    }
}
