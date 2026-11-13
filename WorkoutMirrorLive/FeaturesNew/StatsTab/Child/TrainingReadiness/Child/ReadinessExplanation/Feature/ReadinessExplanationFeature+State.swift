//
//  ReadinessExplanationFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `ReadinessExplanationFeature` state
extension ReadinessExplanationFeature {

    @ObservableState
    struct State: Equatable {

        /// The level shown on the card this was opened from.
        ///
        /// Only tints the background, the way the metric details screen tints its
        /// own — so the sheet reads as belonging to the card it came out of.
        let level: ReadinessLevel

        /// Creates the state.
        ///
        /// - Parameter level: The level currently on the card
        init(level: ReadinessLevel) {
            self.level = level
        }
    }

}
