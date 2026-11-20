//
//  ReadinessExplanationFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture

/// A feature that explains how the readiness score is produced.
///
/// Holds no state beyond the level it was opened at: the explanation is the same
/// every time. It exists as a feature rather than a local flag because a view may
/// not own presentation state.
@Reducer
struct ReadinessExplanationFeature {

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { _, action in
            switch action {

                // MARK: - View Actions

            case .view(.closeButtonTapped):
                return .run { _ in await dismiss() }
            }
        }
    }
}
