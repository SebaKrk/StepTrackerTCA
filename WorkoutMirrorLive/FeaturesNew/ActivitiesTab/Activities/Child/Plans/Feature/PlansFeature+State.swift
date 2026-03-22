//
//  PlansFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension PlansFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// Training session plans loaded from SQLite.
        var sessions: [TrainingSession] = []

        /// Current view state.
        var viewState: ViewState = .loading

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }

}
