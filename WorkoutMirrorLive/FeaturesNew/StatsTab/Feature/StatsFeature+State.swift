//
//  StatsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `StatsFeature` state
extension StatsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: ViewState = .success
        
        /// The currently selected stats context display on the stats view.
        /// - Default: `.today`
        var context: StatsFeatureContext = .today
        
        // MARK: - Destination
        
        /// destination from SummaryFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        ///
        var trainingReadiness: TrainingReadinessFeature.State = .init()
    }
    
}
