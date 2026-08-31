//
//  PRBoardFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

extension PRBoardFeature {

    @ObservableState
    struct State: Equatable {
        @Presents var movementList: PRMovementListFeature.State?
    }
}
