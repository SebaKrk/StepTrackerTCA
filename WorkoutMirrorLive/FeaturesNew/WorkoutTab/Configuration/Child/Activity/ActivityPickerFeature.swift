//
//  ActivityPickerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct ActivityPickerFeature {
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - Action
            case let .select(value):
                state.selected = value
                return .none

                // MARK: - View Action
            case let .view(.buttonTapped(value)):
                return .send(.select(value))

            case let .view(.toggleVisibility(workout)):
                state.$visibleWorkoutKeys.withLock { keys in
                    let key = workout.storageKey
                    if keys.contains(key) {
                        // Currently visible — ignore tap. Exactly 3 are required,
                        // so visible items are read-only; user must tap a hidden
                        // one to trigger a FIFO swap.
                        return
                    }
                    // Toggle on — FIFO swap if already at the 3-item cap.
                    if keys.count >= 3 {
                        keys.removeFirst()
                    }
                    keys.append(key)
                }
                return .none
            }
        }
    }
}

/// Implementation of `ActivityPickerFeature` action
extension ActivityPickerFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        ///
        case select(WorkoutType)

        // MARK: - View Actions
        case view(View)

        enum View {

            /// User tapped a workout icon in the quick picker — select it for the session.
            case buttonTapped(WorkoutType)

            /// User toggled a workout's visibility in the overflow menu — add/remove it
            /// from the quick picker row (persisted via `@Shared(.appStorage)`).
            case toggleVisibility(WorkoutType)
        }
    }
}

/// Implementation of `ActivityPickerFeature` state
extension ActivityPickerFeature {

    @ObservableState
    struct State {

        /// User-configurable list of workout types shown in the quick picker row.
        /// Stored as `[String]` of `WorkoutType.storageKey` so it survives renames /
        /// removed cases gracefully (`compactMap` filters unknown keys).
        @Shared(.appStorage(.quickPickerWorkouts))
        var visibleWorkoutKeys: [String] = ["cross", "functional", "cycling"]

        /// Decoded version of `visibleWorkoutKeys` — view iterates over this.
        var visibleWorkouts: [WorkoutType] {
            visibleWorkoutKeys.compactMap(WorkoutType.init(storageKey:))
        }

        /// All `WorkoutType` cases — used in the overflow menu for visibility management.
        var allWorkouts: [WorkoutType] { WorkoutType.allCases }

        /// Workouts sorted for the visibility menu — currently visible ones first
        /// (in selection order), then hidden ones in default `allCases` order.
        var sortedWorkouts: [WorkoutType] {
            visibleWorkouts + hiddenWorkouts
        }

        /// `WorkoutType` cases not currently in the quick picker row.
        var hiddenWorkouts: [WorkoutType] {
            WorkoutType.allCases.filter { !visibleWorkouts.contains($0) }
        }

        ///
        var selected: WorkoutType? = nil
    }

}

