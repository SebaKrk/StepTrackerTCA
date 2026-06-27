//
//  SetInputFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct SetInputFeature {

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                // TextField'y dla reps/weight (simple + per-set) bind'ują się BEZPOŚREDNIO
                // do `store.exercises[i].actualReps/actualWeight/sets[].reps/weight` przez
                // `@Bindable` w View → BindingReducer obsługuje mutacje synchronicznie.
                // To zapobiega ifLet warning'owi: gdy sheet dismissie, SwiftUI invalidate'uje
                // bindingi (NIE wysyła pending updates jako presentation actions).
                return .none

            // MARK: - Confirm / Cancel

            case .view(.addTapped):
                state.confirmed = true
                return .run { _ in await self.dismiss() }

            case .view(.cancelTapped):
                state.confirmed = false
                return .run { _ in await self.dismiss() }
            }
        }
    }
}
