//
//  ExerciseDetailFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ExerciseDetailFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Receives fetched logs from the async effect.
        case logsLoaded([ExerciseLog])

        // MARK: - View Actions

        case view(View)

        @CasePathable
        enum View {
            /// Triggered when the view appears on screen.
            case onAppear
            /// User tapped a history row to navigate to the workout detail.
            case historyRowTapped(UUID)
        }
    }
}
