//
//  SummaryFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation
    
    /// Represents the state for `SummaryFeature`
extension SummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The summary data representing the user's workout information.
        /// This property is used as a source for processing and grouping workout movements.
        /// - Note: The summary can be `nil` if it has not been fetched or initialized yet.
        var summary: Summary?
        
        ///
        /// An array of grouped movements derived from the summary data.
        /// This property is populated when the summary data is processed into categorized groups.
        /// - Note: This is intended to facilitate display and further processing of the workout data.
        var groupedMovements: [GroupedMovement] = []
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
        
    }
}
