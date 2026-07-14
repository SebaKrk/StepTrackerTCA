//
//  WorkoutVolumeFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

extension WorkoutVolumeFeature {

    @CasePathable
    enum Action: ViewAction {

        case `internal`(Internal)

        enum Internal {
            /// Triggers fetching and aggregating workout data from HealthKit.
            case fetchData

            /// Receives the result of the workout data fetch.
            case dataResponse(Result<[WeeklyActivitySegment], Error>)

            /// Triggers the chart drawing animation after a short delay.
            case revealChart
        }

        case view(View)

        enum View {
            /// Triggered when the view appears on screen.
            case viewDidAppear

            /// Triggered by pull-to-refresh.
            case refresh

            /// Triggered when user changes the date range selector.
            case dateRangeChanged(ActivityDateRange)
        }
    }
}
