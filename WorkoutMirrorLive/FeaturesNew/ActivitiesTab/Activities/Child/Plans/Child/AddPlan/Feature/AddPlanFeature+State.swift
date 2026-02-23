//
//  AddPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import IdentifiedCollections
import SharedModels
import SwiftUI

extension AddPlanFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        /// Planned workouts shared across the app — AddPlanFeature owns persistence for manual entry path.
        @Shared(.inMemory("plannedWorkouts"))
        var plannedWorkouts: IdentifiedArrayOf<TrainingSession> = []

        /// Current view state.
        var viewState: ViewState = .success

        // MARK: - Destination

        @Presents var destination: Destination.State?
    }

}
