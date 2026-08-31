//
//  PRMovementListFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

extension PRMovementListFeature {

    @ObservableState
    struct State: Equatable {
        let category: PRCategory
        @Presents var detail: PRMovementDetailFeature.State?

        /// Subgroups of this category in catalog declaration order.
        var sections: [(subgroup: PRSubgroup, movements: [PRMovement])] {
            var order: [PRSubgroup] = []
            var grouped: [PRSubgroup: [PRMovement]] = [:]
            for movement in PRCatalog.movements(in: category) {
                if grouped[movement.subgroup] == nil { order.append(movement.subgroup) }
                grouped[movement.subgroup, default: []].append(movement)
            }
            return order.map { (subgroup: $0, movements: grouped[$0] ?? []) }
        }
    }
}
