//
//  HealthMetricSummaryCardFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `HealthMetricSummaryCardFeature` action
extension HealthMetricSummaryCardFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            ///
            case changeContentState(ContentState)
            
            /// Action triggered when the night has not ended yet, carrying the
            /// components that do not depend on it.
            case awaitingSleepData(TrainingReadinessComponents)

            ///
            case dataLoaded(TrainingReadinessComponents?)
            
            ///
            case loadSummaryData
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            //case showDetailsButtonTapped
            case showDetailsButtonTapped(metric: HealthMetricType, data: TrainingComponentScore)
            
            /// Action triggered when user pulls to refresh
            case refresh

            /// Action triggered when the unlock button on the locked cards is tapped
            case unlockButtonTapped
        }
        
        // MARK: - Destination

        /// Destination case for handling navigation actions.
        /// - Parameter action: The action to be performed within the destination.
        case destination(PresentationAction<Destination.Action>)

        // MARK: - Delegate Action

        case delegate(Delegate)

        enum Delegate {

            /// Signals to parent that this feature has finished its refresh cycle
            /// (entered a terminal state — `.ready`, `.noData`, or `.unauthorized`).
            case refreshDidComplete

            /// Asks the parent to present the offer of Pro.
            case unlockRequested
        }
    }

}
