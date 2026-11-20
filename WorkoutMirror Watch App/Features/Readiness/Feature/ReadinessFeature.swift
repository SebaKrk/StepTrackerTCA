//
//  ReadinessFeature.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels

/// Drives the readiness screen shown while no workout is active.
///
/// The score is calculated on the paired iPhone and pushed over the
/// WatchConnectivity application context; this feature only receives it.
@Reducer
struct ReadinessFeature {

    // MARK: - Dependencies

    @Dependency(\.watchConnectivityClientAW) var watchClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.onAppear):
                apply(watchClient.latestReadinessDelivery(), to: &state)
                return .run { send in
                    for await delivery in watchClient.readinessDeliveryStream() {
                        await send(.deliveryReceived(delivery))
                    }
                }
                .cancellable(id: CancelID.readinessStream, cancelInFlight: true)

            case let .deliveryReceived(delivery):
                apply(delivery, to: &state)
                return .none

            case .view(.scoreTapped):
                guard !state.isLocked, let snapshot = state.snapshot else { return .none }
                state.details = ReadinessDetailsFeature.State(snapshot: snapshot)
                return .none

            case .details:
                return .none
            }
        }
        .ifLet(\.$details, action: \.details) {
            ReadinessDetailsFeature()
        }
    }

    // MARK: - Helpers

    /// A score replaces the lock and the lock replaces the score, so neither outlives the other.
    private func apply(_ delivery: ReadinessDelivery?, to state: inout State) {
        switch delivery {
        case let .snapshot(snapshot):
            state.snapshot = snapshot
            state.isLocked = false
        case .locked:
            state.snapshot = nil
            state.details = nil
            state.isLocked = true
        case nil:
            break
        }
    }

    // MARK: - Cancellation

    nonisolated enum CancelID: Hashable, Sendable {
        case readinessStream
    }
}
