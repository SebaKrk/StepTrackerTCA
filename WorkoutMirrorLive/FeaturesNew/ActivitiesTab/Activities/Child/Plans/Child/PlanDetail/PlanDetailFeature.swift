//
//  PlanDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@Reducer
struct PlanDetailFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        let trainingSession: TrainingSession

        var isWarmupExpanded: Bool = true
        var isCooldownExpanded: Bool = true
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {
        case view(View)

        @CasePathable
        enum View {
            case closeTapped
            case warmupToggleTapped
            case cooldownToggleTapped
        }
    }

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.closeTapped):
                return .run { _ in await dismiss() }
            case .view(.warmupToggleTapped):
                state.isWarmupExpanded.toggle()
                return .none
            case .view(.cooldownToggleTapped):
                state.isCooldownExpanded.toggle()
                return .none
            }
        }
    }
}
