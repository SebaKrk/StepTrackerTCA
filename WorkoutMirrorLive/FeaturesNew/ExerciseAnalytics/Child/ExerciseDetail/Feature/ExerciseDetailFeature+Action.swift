//
//  ExerciseDetailFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

extension ExerciseDetailFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Receives fetched logs from the async effect.
        case logsLoaded([ExerciseLog])

        /// HKWorkout + maxHR fetched — present activity detail.
        case activityLoaded(HKWorkout, Double)

        /// HKWorkout fetch failed.
        case activityLoadFailed

        /// Presentation action for activity detail.
        case activityDetail(PresentationAction<ActivityDetailsFeature.Action>)

        // MARK: - View Actions

        case view(View)

        @CasePathable
        enum View {
            
            /// Triggered when the view appears on screen.
            case onAppear
            
            /// User tapped a history row to navigate to the workout detail.
            case historyRowTapped(UUID)

            /// User tapped dismiss button.
            case dismissTapped

            /// User tapped Copy in the DEBUG-only "Unrecognized names" card —
            /// puts the raw-name list on the pasteboard for catalog extension work.
            case copyUnmatchedNamesTapped
        }
    }
}
