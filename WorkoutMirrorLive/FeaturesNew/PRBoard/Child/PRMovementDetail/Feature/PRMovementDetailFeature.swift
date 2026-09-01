//
//  PRMovementDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct PRMovementDetailFeature {

    // MARK: - Dependency

    @Dependency(\.date.now) var now

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.addEntryTapped):
                state.editor = PREntryEditorFeature.State(movement: state.movement, now: now)
                return .none

            case .editor:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            PREntryEditorFeature()
        }
    }
}
