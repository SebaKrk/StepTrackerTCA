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

        /// Unrecognized-names report written to a temp file — present the share sheet.
        case reportFileReady(URL)

        // MARK: - Alert

        /// Confirmation alert before sharing the unrecognized-names report.
        case alert(PresentationAction<Alert>)

        enum Alert {
            case sendReportConfirmed
        }

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

            /// User tapped Copy in the "Unrecognized names" card (DEBUG-only button) —
            /// puts the raw-name list on the pasteboard for catalog extension work.
            case copyUnmatchedNamesTapped

            /// User tapped "Wyślij do developera" — shows the confirmation alert.
            case sendToDeveloperTapped

            /// Share sheet was dismissed — clears the temp-file state.
            case shareSheetDismissed
        }
    }
}
