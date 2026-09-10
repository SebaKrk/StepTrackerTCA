//
//  RoundsDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 09/09/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels
import SwiftUI

/// Drill-down analysis of a rounds-timer workout: raw HR samples fetched from
/// HealthKit and cut by the `RoundSegment` timeline read from the workout's
/// own `.segment` events. All math lives in `RoundsAnalysis` (pure).
@Reducer
struct RoundsDetailFeature {

    // MARK: - Dependency

    @Dependency(\.healthStore) var healthStore

    // MARK: - State

    @ObservableState
    struct State {

        /// Color representing training readiness level, shared across features —
        /// paints the same background gradient as every activity screen.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The workout being analyzed.
        var workout: HKWorkout

        /// User's max HR — anchors the zone colors of both charts.
        var maxHeartRate: Double

        /// Round timeline parsed from the workout's segment events.
        var segments: [RoundSegment]

        /// Computed analysis; nil while loading or when no round carried HR.
        var analysis: RoundsAnalysis?

        /// Downsampled HR curve feeding the "HR × rounds" chart (≤ ~400 points
        /// so the line stays cheap to render).
        var hrCurve: [(date: Date, bpm: Double)] = []

        /// True until the HR fetch settles — drives the loading placeholder.
        var isLoading = true
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case `internal`(Internal)

        enum Internal {

            /// nil analysis = no HR samples inside any round (sensor absent) —
            /// the screen shows the empty placeholder instead of charts.
            case analysisLoaded(RoundsAnalysis?, curve: [(date: Date, bpm: Double)])
        }

        case view(View)

        enum View {

            /// Starts the HR fetch on first appearance.
            case viewDidAppear
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.viewDidAppear):
                guard state.isLoading, state.analysis == nil else { return .none }
                return .run { [healthStore, workout = state.workout, segments = state.segments] send in
                    // Silent fail — no HR (e.g. indoor without any sensor) shows
                    // the empty placeholder, same convention as HeartRateZones.
                    let samples = (try? await WorkoutSummaryLoader.heartRateSamples(
                        for: workout,
                        healthStore: healthStore
                    )) ?? []
                    let step = max(1, samples.count / 400)
                    let curve = samples.enumerated()
                        .filter { $0.offset.isMultiple(of: step) }
                        .map(\.element)
                    await send(.internal(.analysisLoaded(
                        RoundsAnalysis.analyze(samples: samples, segments: segments),
                        curve: curve
                    )))
                }

            case let .internal(.analysisLoaded(analysis, curve)):
                state.analysis = analysis
                state.hrCurve = curve
                state.isLoading = false
                return .none
            }
        }
    }
}
