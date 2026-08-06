//
//  ImportPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import OSLog
import SharedModels

@Reducer
struct ImportPlanFeature {

    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(.qrScanned(string)):
                guard let payload = try? SharedPlanCodec.decode(string) else {
                    // Bump the attempt id so the view remounts a fresh scanner —
                    // the one-shot QRScannerView has stopped its session, and
                    // without a remount the camera stays frozen with no retry.
                    state.scanAttempt += 1
                    state.alert = Self.malformedAlert
                    return .none
                }
                // Fresh identity at every level (see withNewIdentity) — B's own copy,
                // not a clone of A. Import time so it sorts to the top of B's list.
                state.scannedPlan = payload.plan.withNewIdentity(id: uuid(), date: now)
                return .none

            case .view(.addTapped):
                guard let plan = state.scannedPlan else { return .none }
                // Delegate upward; PlansFeature is the single writer.
                return .run { send in
                    await send(.delegate(.imported(plan)))
                    await dismiss()
                }

            case .view(.cancelTapped):
                return .run { _ in await dismiss() }

            case .delegate, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    static let malformedAlert = AlertState<Action.Alert> {
        TextState(String(localized: "Couldn't read the plan"))
    } message: {
        TextState(String(localized: "This code doesn't contain a valid training plan."))
    }
}
