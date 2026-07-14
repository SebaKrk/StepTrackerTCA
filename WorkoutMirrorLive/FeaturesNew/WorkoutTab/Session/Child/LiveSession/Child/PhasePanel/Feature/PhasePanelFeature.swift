//
//  PhasePanelFeature.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Child feature of `LiveSessionFeature` responsible for navigating through
/// training plan phases and running a per-phase timer during a live workout.
///
/// Shown only when a `TrainingSession` is associated with the current workout.
/// Supports countdown mode (when the phase has a `timeCap`) and stopwatch mode.
@Reducer
struct PhasePanelFeature {

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.appeared):
                state.phaseTimestamps.append(
                    State.PhaseTimestamp(
                        phaseName: state.currentPhase.title,
                        startDate: Date()
                    )
                )
                return .send(.timerTick)

            case .view(.timerTapped):
                return .send(.delegate(.timerManagementRequested(elapsedSeconds: state.elapsedSeconds)))

            case .delegate:
                return .none

            case .view(.nextPhaseTapped):
                guard state.canGoNext else { return .none }
                guard Date().timeIntervalSince(
                    state.phaseTimestamps.last?.startDate ?? .distantPast
                ) > 5 else { return .none }
                state.phaseTimestamps[state.phaseTimestamps.count - 1].endDate = Date()
                state.currentIndex += 1
                state.elapsedSeconds = 0
                state.phaseTimestamps.append(
                    State.PhaseTimestamp(
                        phaseName: state.currentPhase.title,
                        startDate: Date()
                    )
                )
                return .none

            case .view(.previousPhaseTapped):
                guard state.canGoPrevious else { return .none }
                guard Date().timeIntervalSince(
                    state.phaseTimestamps.last?.startDate ?? .distantPast
                ) > 5 else { return .none }
                state.phaseTimestamps[state.phaseTimestamps.count - 1].endDate = Date()
                state.currentIndex -= 1
                state.elapsedSeconds = 0
                state.phaseTimestamps.append(
                    State.PhaseTimestamp(
                        phaseName: state.currentPhase.title,
                        startDate: Date()
                    )
                )
                return .none

            case .timerTick:
                guard state.timerRunning else { return .none }
                state.elapsedSeconds += 1
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    await send(.timerTick)
                }
                .cancellable(id: PhasePanelFeatureCancelID.timer, cancelInFlight: true)

            }
        }
    }

}
