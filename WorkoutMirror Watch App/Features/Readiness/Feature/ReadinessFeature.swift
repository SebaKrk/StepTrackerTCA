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
                state.snapshot = watchClient.latestReadinessSnapshot()
                return .run { send in
                    for await snapshot in watchClient.readinessSnapshotStream() {
                        await send(.snapshotReceived(snapshot))
                    }
                }
                .cancellable(id: CancelID.readinessStream, cancelInFlight: true)

            case let .snapshotReceived(snapshot):
                state.snapshot = snapshot
                return .none

            case .view(.scoreTapped):
                guard let snapshot = state.snapshot, snapshot.isReliable else { return .none }
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

    // MARK: - Cancellation

    nonisolated enum CancelID: Hashable, Sendable {
        case readinessStream
    }
}
