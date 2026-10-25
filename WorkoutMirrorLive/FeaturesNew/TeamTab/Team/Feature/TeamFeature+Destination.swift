//
//  TeamFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation

extension TeamFeature {

    @Reducer
    enum Destination {

        /// Sheet for naming a new group.
        case createGroup(CreateGroupFeature)
    }

}
