//
//  ReadinessTrendFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

extension ReadinessTrendFeature {

    @CasePathable
    enum Action: ViewAction {

        case `internal`(Internal)

        enum Internal {
            /// Triggers fetching training readiness history from the client.
            case fetchData

            /// Receives the result of the readiness data fetch.
            case dataResponse(Result<[TrainingReadinessResult], Error>)

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

            /// Triggered when user taps a data point on the chart.
            case dataPointSelected(TrainingReadinessResult?)
        }
    }
}
