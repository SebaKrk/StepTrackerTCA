//
//  PRMovementDetailFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import SharedModels

extension PRMovementDetailFeature {

    @ObservableState
    struct State: Equatable {

        /// Catalog movement this detail screen presents.
        let movement: PRMovement

        /// "Add result" editor sheet, presented from the toolbar or the empty state.
        @Presents var editor: PREntryEditorFeature.State?

        init(movement: PRMovement) {
            self.movement = movement
        }
    }
}
