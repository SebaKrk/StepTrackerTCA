//
//  TrainingSessionTabFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/06/2025.
//

import ComposableArchitecture

extension TrainingSessionTabFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `CountDownFeature`.
        case countDown(CountDownFeature)
    }
    
}
