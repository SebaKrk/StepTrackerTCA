//
//  SharePlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct SharePlanFeature {

    @Dependency(\.planShareClient) var planShareClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.viewDidAppear):
                let plan = state.plan
                return .run { send in
                    let result = try await planShareClient.qrPayload(plan)
                    await send(.qrResultLoaded(result))
                } catch: { _, send in
                    // Encoding threw — surface an error state instead of spinning forever.
                    await send(.qrResultLoaded(.failed))
                }

            case let .qrResultLoaded(result):
                state.qrResult = result
                return .none
            }
        }
    }
}
