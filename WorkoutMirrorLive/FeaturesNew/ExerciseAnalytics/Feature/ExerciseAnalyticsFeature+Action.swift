//
//  ExerciseAnalyticsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ExerciseAnalyticsFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Receives fetched logs from the async effect.
        case logsLoaded([ExerciseLog])

        /// Triggers chart reveal animation after data loads.
        case revealChart

        // MARK: - Destination

        /// Presentation action for exercise detail drilldown.
        case detail(PresentationAction<ExerciseDetailFeature.Action>)

        // MARK: - View Actions

        case view(View)

        @CasePathable
        enum View {
            
            /// Triggered when the view appears on screen.
            case onAppear
            
            /// User navigated to a different month.
            case monthChanged(Date)
            
            /// User changed the sort mode picker.
            case sortModeChanged(ExerciseAnalyticsSortMode)
            
            /// User tapped an exercise row.
            case exerciseTapped(ExerciseType)
        }
    }
}
