//
//  DeviceFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `DeviceFeature` state
extension DeviceFeature {

    @ObservableState
    struct State: Equatable {

        /// HR source the user committed to; `nil` until a tile is confirmed.
        var selected: DeviceOption? = nil

        /// Shown when the user picks "Other HR device" — reminds them to enable
        /// HR broadcasting before the choice is committed.
        @Presents var broadcastAlert: AlertState<BroadcastAlertAction>?
    }
}
