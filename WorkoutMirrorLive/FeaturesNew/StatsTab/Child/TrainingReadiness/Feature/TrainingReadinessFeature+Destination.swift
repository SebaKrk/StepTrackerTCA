//
//  TrainingReadinessFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture

/// Implementation of `TrainingReadinessFeature` destination
extension TrainingReadinessFeature {

    @Reducer
    enum Destination {

        /// Explains how the score is produced and what it cannot know.
        case explanation(ReadinessExplanationFeature)
    }

}
